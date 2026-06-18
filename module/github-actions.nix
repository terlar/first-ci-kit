{ lib, config, ... }:

let
  inherit (lib) types;

  enabledJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) config.jobs;

  resolveBranchKey = key: if key == "default" then config.github-actions.defaultBranch else key;

  pushBranches = lib.pipe enabledJobs [
    builtins.attrValues
    (lib.concatMap (job: lib.attrNames (lib.filterAttrs (_: b: b.triggers.onPush) job.branches)))
    (map resolveBranchKey)
    lib.unique
  ];

  pullRequestBranches = lib.pipe enabledJobs [
    builtins.attrValues
    (lib.concatMap (
      job: lib.attrNames (lib.filterAttrs (_: b: b.triggers.onMergeRequest) job.branches)
    ))
    (map resolveBranchKey)
    lib.unique
  ];

  renderInput =
    _name: input:
    lib.mergeAttrsList [
      { inherit (input) type; }
      (lib.optionalAttrs input.required { required = true; })
      (lib.optionalAttrs (input.default != null) { inherit (input) default; })
      (lib.optionalAttrs (input.description != "") { inherit (input) description; })
      (lib.optionalAttrs (input.options != [ ]) { inherit (input) options; })
    ];

  renderOutput =
    _name: output:
    lib.mergeAttrsList [
      { inherit (output) value; }
      (lib.optionalAttrs (output.description != "") { inherit (output) description; })
    ];

  workflowCall = lib.mergeAttrsList [
    (lib.optionalAttrs (config.inputs != { }) { inputs = lib.mapAttrs renderInput config.inputs; })
    (lib.optionalAttrs (config.outputs != { }) {
      outputs = lib.mapAttrs renderOutput config.outputs;
    })
  ];
in
{
  options.github-actions = {
    generate = lib.mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to generate a GitHub Actions workflow file for this pipeline.
        Set to `false` to opt out of file generation (e.g. for pipelines that
        only target another backend such as GitLab CI).
      '';
    };

    settings = lib.mkOption {
      type = config.types.yamlType;
      default = { };
      description = "Configuration written for job to {file}`workflow.yml`.";
      example = lib.literalExpression ''
        {
          name = "CI";
          on = [ "push" ];
          env.DAY_OF_WEEK = "Monday";
        }
      '';
    };

    defaultRunsOn = lib.mkOption {
      type = with types; nullOr (either str (listOf str));
      default = null;
      description = "The default runs-on to use for jobs";
    };

    transformJobName = lib.mkOption {
      type = types.functionTo types.str;
      default = lib.id;
      description = "A function to transform job names";
    };

    checkoutAction = lib.mkOption {
      type = types.str;
      default = "actions/checkout@v7";
      description = "The default checkout action to use for jobs";
      example = "actions/checkout@v5";
    };

    uploadArtifactAction = lib.mkOption {
      type = types.str;
      default = "actions/upload-artifact@v7";
      description = "The upload-artifact action to use for artifact upload steps";
      example = "actions/upload-artifact@v3";
    };

    downloadArtifactAction = lib.mkOption {
      type = types.str;
      default = "actions/download-artifact@v8";
      description = "The download-artifact action to use for artifact download steps";
      example = "actions/download-artifact@v3";
    };

    defaultBranch = lib.mkOption {
      type = types.str;
      default = "main";
      description = ''
        The name of the default branch. Used to resolve the special `"default"`
        branch key in `job.branches` when auto-populating
        `on.push.branches` and `on.pull_request.branches`.
      '';
      example = "master";
    };

    changes = {
      enable = lib.mkEnableOption ''
        auto-injection of `changes` and `changes_key` string inputs into this
        pipeline's `on.workflow_call.inputs`. Enable this on pipelines that are
        called via `pipelineCall` from a parent job that has change detection
        (`branches.*.changes.paths`) configured, so that GitHub Actions accepts
        the inputs the parent passes automatically.
      '';
    };

    forceRunAll = {
      enable =
        lib.mkEnableOption ''
          auto-injection of a `force_run_all` boolean input and a `workflow_dispatch`
          trigger into the generated workflow. When the input is set to `true` at
          runtime, change detection is skipped and all jobs are treated as affected.
          Enabled by default whenever the auto-generated `changes` job is present.
        ''
        // {
          default = true;
        };

      inputName = lib.mkOption {
        type = types.str;
        default = "force_run_all";
        description = "Name of the generated `workflow_dispatch` / `workflow_call` input.";
        example = "run_all";
      };
    };

    changesFetchDepth = lib.mkOption {
      type = types.int;
      default = 0;
      description = ''
        `fetch-depth` passed to the checkout action in the auto-generated
        `changes` job. Defaults to `0` (full history) because the change
        detection script compares arbitrary commits and requires the full
        git history to be available.
      '';
      example = 50;
    };

    summaryJob = {
      enable = lib.mkEnableOption "workflow summary job that runs last and links to all non-skipped jobs";

      name = lib.mkOption {
        type = types.str;
        default = "summary";
        description = "Key name for the generated summary job.";
        example = "workflow-summary";
      };

      runsOn = lib.mkOption {
        type = with types; nullOr (either str (listOf str));
        default = null;
        description = ''
          `runs-on` for the summary job. Falls back to
          `github-actions.defaultRunsOn` when `null`.
        '';
        example = "ubuntu-latest";
      };
    };

    file = lib.mkOption {
      internal = true;
      type = types.package;
      default = lib.pipe config.github-actions.settings [
        builtins.toJSON
        (builtins.toFile "workflow.yml")
      ];
      description = "Package of the workflow.yml";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf config.github-actions.changes.enable {
      github-actions.settings.on.workflow_call.inputs = {
        changes = {
          type = "string";
          description = "Change detection JSON passed from the calling workflow.";
        };
        changes_key = {
          type = "string";
          description = "Key identifying this job in the change detection map.";
        };
      };
    })
    (lib.mkIf (pushBranches != [ ]) {
      github-actions.settings.on.push.branches = lib.mkDefault pushBranches;
    })
    (lib.mkIf (pullRequestBranches != [ ]) {
      github-actions.settings.on.pull_request.branches = lib.mkDefault pullRequestBranches;
    })
    (lib.mkIf (workflowCall != { }) {
      github-actions.settings.on.workflow_call = workflowCall;
    })
    (lib.mkIf (config.autoEnvInputs && config.inputs != { }) {
      github-actions.settings.env = lib.mapAttrs' (name: _: {
        name = lib.strings.toUpper name;
        value = "\${{ inputs.${name} }}";
      }) config.inputs;
    })
  ];
}
