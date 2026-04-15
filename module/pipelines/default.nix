{ lib, config, ... }:

let
  parentPipelineName = config._module.args.parentPipelineName or "";

  mkReusableWorkflow = import ../jobs/github-actions/reusable-workflow.nix { inherit lib; };

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

  # Build workflow_call attrset from child's inputs/outputs
  mkWorkflowCall =
    child:
    let
      hasInputs = child.inputs != { };
      hasOutputs = child.outputs != { };

      renderInput =
        _name: input:
        {
          inherit (input) type;
        }
        // lib.optionalAttrs input.required { required = true; }
        // lib.optionalAttrs (input.default != null) { inherit (input) default; }
        // lib.optionalAttrs (input.description != "") { inherit (input) description; }
        // lib.optionalAttrs (input.options != [ ]) { inherit (input) options; };

      renderOutput =
        _name: output:
        {
          inherit (output) value;
        }
        // lib.optionalAttrs (output.description != "") { inherit (output) description; };
    in
    { }
    // lib.optionalAttrs hasInputs { inputs = lib.mapAttrs renderInput child.inputs; }
    // lib.optionalAttrs hasOutputs { outputs = lib.mapAttrs renderOutput child.outputs; };

  # Build caller job + reusable workflow for one child pipeline (GHA)
  mkGhaDispatch =
    childName: child:
    let
      workflowCall = mkWorkflowCall child;
      hasWorkflowCall = workflowCall != { };

      enabledChildJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) child.jobs;

      inherit (child.github-actions) transformJobName;

      renderedChildJobs = lib.mapAttrs' (name: job: {
        name = transformJobName name;
        value = builtins.removeAttrs job.github-actions [ "enable" ];
      }) enabledChildJobs;

      childChanges = lib.pipe enabledChildJobs [
        (builtins.mapAttrs (_: job: job.branches.default.changes.paths or [ ]))
        (lib.filterAttrs (_: paths: paths != [ ]))
        (builtins.mapAttrs (_: builtins.concatStringsSep "\\|"))
        (lib.mapAttrsToList (name: paths: "${name}:${paths}"))
      ];

      reusableWorkflow =
        mkReusableWorkflow {
          jobs = renderedChildJobs;
          changes = childChanges;
          inherit (child.github-actions) checkoutAction defaultRunsOn;
        }
        // lib.optionalAttrs hasWorkflowCall { on.workflow_call = workflowCall; }
        // child.github-actions.dispatch.settings;

      callerJob = {
        uses = "./.github/workflows/${childName}.yml";
        secrets = "inherit";
      }
      // lib.optionalAttrs (child.github-actions.dispatch.callerIf != null) {
        "if" = child.github-actions.dispatch.callerIf;
      }
      // lib.optionalAttrs (child.github-actions.dispatch.callerNeeds != [ ]) {
        needs = child.github-actions.dispatch.callerNeeds;
      };
    in
    {
      caller = {
        ${childName} = callerJob;
      };
      reusable = {
        ${childName} = reusableWorkflow;
      };
    };

in
{
  imports = [ ./interface.nix ];

  config = {
    gitlab-ci.settings = lib.mkMerge (lib.mapAttrsToList mkGitlabDispatchJobs config.pipelines);

    github-actions.settings.jobs = lib.mkMerge (
      lib.mapAttrsToList (childName: child: (mkGhaDispatch childName child).caller) config.pipelines
    );

    github-actions.reusableWorkflowSettings = lib.mkMerge (
      lib.mapAttrsToList (childName: child: (mkGhaDispatch childName child).reusable) config.pipelines
    );
  };
}
