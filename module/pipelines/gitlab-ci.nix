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
        if child.gitlab-ci.image != null then
          config.imageRegistry.${child.gitlab-ci.image} or child.gitlab-ci.image
        else
          null;

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
          ) (ci-lib.expandPipelineNeeds config.jobSets child.needs);
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
in
{
  config.gitlab-ci.settings = lib.mkMerge (lib.mapAttrsToList mkGitlabDispatchJobs config.pipelines);
}
