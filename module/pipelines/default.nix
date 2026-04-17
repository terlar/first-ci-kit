{
  lib,
  ci-lib,
  config,
  ...
}:

let
  parentPipelineName = config._module.args.parentPipelineName or "";

  # Expand a single pipeline need: jobSet → list of { job, optional, artifacts };
  # job → singleton list of { job, optional, artifacts }.
  expandPipelineNeed =
    need:
    if need.jobSet != null then
      map (job: {
        inherit job;
        inherit (need) optional artifacts;
      }) config.jobSets.${need.jobSet}.jobs
    else
      [
        {
          inherit (need) job optional artifacts;
        }
      ];

  # Expand all pipeline needs into a flat list of { job, optional, artifacts }.
  expandPipelineNeeds = needs: lib.flatten (map expandPipelineNeed needs);

  # Resolve image from tags via imageRegistry
  resolveImage =
    tags: imageRegistry:
    let
      matchingTag = lib.findFirst (t: imageRegistry ? ${t}) null tags;
    in
    if matchingTag != null then imageRegistry.${matchingTag} else null;

  # Build the generate + trigger jobs for one child pipeline (GitLab CI)
  mkGitlabDispatchJobs =
    childName: child:
    let
      artifactFile = "gitlab-ci-${childName}.yml";
      generateJobName = "generate-${childName}";
      triggerJobName = "trigger-${childName}";
      buildTarget = "ci-pipeline-gitlab-ci-${parentPipelineName}-${childName}";

      image = resolveImage child.tags config.imageRegistry;

      generateJob =
        { }
        // lib.optionalAttrs (image != null) { inherit image; }
        // {
          script = [
            "nix build .#${buildTarget}"
            "cp result ${artifactFile}"
          ];
          artifacts = {
            paths = [ artifactFile ];
            expire_in = "1 week";
          };
        }
        // lib.optionalAttrs (child.needs != [ ]) {
          needs = map (
            n:
            {
              job = n.job;
            }
            // lib.optionalAttrs (!n.artifacts) { artifacts = false; }
            // lib.optionalAttrs n.optional { optional = true; }
          ) (expandPipelineNeeds child.needs);
        }
        // lib.optionalAttrs (child.gitlab-ci.dispatch.generateJob.beforeScript != [ ]) {
          before_script = child.gitlab-ci.dispatch.generateJob.beforeScript;
        }
        // lib.optionalAttrs (child.gitlab-ci.dispatch.generateJob.extraRules != [ ]) {
          rules = child.gitlab-ci.dispatch.generateJob.extraRules;
        }
        // lib.optionalAttrs (config.gitlab-ci.defaultStage != null) {
          stage = config.gitlab-ci.defaultStage;
        };

      triggerAttr = {
        include = [
          {
            artifact = artifactFile;
            job = generateJobName;
          }
        ];
      }
      // lib.optionalAttrs (child.gitlab-ci.dispatch.trigger.strategy != null) {
        inherit (child.gitlab-ci.dispatch.trigger) strategy;
      }
      // lib.optionalAttrs (child.gitlab-ci.dispatch.trigger.forward != null) {
        inherit (child.gitlab-ci.dispatch.trigger) forward;
      };

      triggerJob = {
        stage = ".post";
        needs = [ { job = generateJobName; } ];
        trigger = triggerAttr;
      };
    in
    {
      ${generateJobName} = generateJob;
      ${triggerJobName} = triggerJob;
    };

  # Build caller job for one child pipeline (GHA)
  mkGhaDispatch =
    childName: child:
    let
      callerNeeds = map (n: config.github-actions.transformJobName n.job) (expandPipelineNeeds child.needs);

      callerJob =
        {
          uses = "./.github/workflows/${childName}.yml";
          secrets = "inherit";
        }
        // lib.optionalAttrs (child.github-actions.dispatch.callerIf != null) {
          "if" = child.github-actions.dispatch.callerIf;
        }
        // lib.optionalAttrs (callerNeeds != [ ]) {
          needs = callerNeeds;
        };
    in
    { ${childName} = callerJob; };

in
{
  imports = [ ./interface.nix ];

  config = {
    gitlab-ci.settings = lib.mkMerge (lib.mapAttrsToList mkGitlabDispatchJobs config.pipelines);

    github-actions.settings.jobs = lib.mkMerge (lib.mapAttrsToList mkGhaDispatch config.pipelines);
  };
}
