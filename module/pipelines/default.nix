{ lib, config, ... }:

let
  parentPipelineName = config._module.args.parentPipelineName or "";

  # Resolve image from tags via imageRegistry
  resolveImage =
    tags: imageRegistry:
    let
      matchingTag = lib.findFirst (t: imageRegistry ? ${t}) null tags;
    in
    if matchingTag != null then imageRegistry.${matchingTag} else null;

  # Build the generate + trigger jobs for one child pipeline
  mkDispatchJobs =
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
  imports = [ ./interface.nix ];

  config.gitlab-ci.settings = lib.mkMerge (lib.mapAttrsToList mkDispatchJobs config.pipelines);
}
