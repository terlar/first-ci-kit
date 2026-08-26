{
  lib,
  ci-lib,
  config,
  ...
}:

let
  parentPipelineName = config._module.args.parentPipelineName or "";

  # Build the generate + trigger jobs for one child pipeline (GitLab CI)
  mkGitlabDispatchJobs =
    childName: child:
    let
      artifactFile = "gitlab-ci-${childName}.yml";
      generateJobName = "generate-${childName}";
      triggerJobName = "trigger-${childName}";
      buildTarget = "ci-pipeline-gitlab-ci-${parentPipelineName}-${childName}";

      image =
        let
          generateImage = child.gitlab-ci.dispatch.generateJob.image;
        in
        if generateImage != null then
          ci-lib.resolveImage config.gitlab-ci.images.repository config.imageRegistry generateImage
        else
          null;

      generateJob = lib.mergeAttrsList [
        (lib.optionalAttrs (image != null) { inherit image; })
        {
          script = [
            "nix build .#${buildTarget}"
            "cp result ${artifactFile}"
          ];
          artifacts = {
            paths = [ artifactFile ] ++ child.gitlab-ci.dispatch.generateJob.extraArtifactPaths;
            expire_in = "1 week";
          };
        }
        (lib.optionalAttrs (child.needs != [ ]) {
          needs = map (
            n:
            lib.mergeAttrsList [
              { inherit (n) job; }
              (lib.optionalAttrs (!n.artifacts) { artifacts = false; })
              (lib.optionalAttrs n.optional { optional = true; })
            ]
          ) (ci-lib.expandPipelineNeeds config.jobSets child.needs);
        })
        (lib.optionalAttrs (child.gitlab-ci.dispatch.generateJob.beforeScript != [ ]) {
          before_script = child.gitlab-ci.dispatch.generateJob.beforeScript;
        })
        (lib.optionalAttrs (child.gitlab-ci.dispatch.generateJob.extraRules != [ ]) {
          rules = child.gitlab-ci.dispatch.generateJob.extraRules;
        })
        (lib.optionalAttrs (config.gitlab-ci.defaultStage != null) {
          stage = config.gitlab-ci.defaultStage;
        })
      ];

      triggerAttr = lib.mergeAttrsList [
        {
          include = [
            {
              artifact = artifactFile;
              job = generateJobName;
            }
          ];
        }
        (lib.optionalAttrs (child.gitlab-ci.dispatch.trigger.strategy != null) {
          inherit (child.gitlab-ci.dispatch.trigger) strategy;
        })
        (lib.optionalAttrs (child.gitlab-ci.dispatch.trigger.forward != null) {
          inherit (child.gitlab-ci.dispatch.trigger) forward;
        })
      ];

      generateStage = config.gitlab-ci.defaultStage;
      triggerStage = child.gitlab-ci.dispatch.trigger.stage;

      triggerJob = lib.mergeAttrsList [
        {
          stage = triggerStage;
          trigger = triggerAttr;
        }
        # When trigger and generate are in the same stage, explicit needs is
        # required for ordering and artifact access. When the trigger is at a
        # later stage (e.g. .post) stage ordering already guarantees the
        # generate job has completed.
        (lib.optionalAttrs (triggerStage == generateStage) {
          needs = [ { job = generateJobName; } ];
        })
        # Mirror the generate job's rules so the trigger only runs when the
        # generate job ran.
        (lib.optionalAttrs (child.gitlab-ci.dispatch.generateJob.extraRules != [ ]) {
          rules = child.gitlab-ci.dispatch.generateJob.extraRules;
        })
      ];
    in
    {
      ${generateJobName} = generateJob;
      ${triggerJobName} = triggerJob;
    };
in
{
  # pipelines is absent when this module is instantiated as a nested pipeline
  # (the option is disabled there, see pipelines/interface.nix)
  config.gitlab-ci.settings = lib.pipe (config.pipelines or { }) [
    (lib.filterAttrs (_: child: !child.gitlab-ci.asComponent))
    (lib.mapAttrsToList mkGitlabDispatchJobs)
    lib.mkMerge
  ];
}
