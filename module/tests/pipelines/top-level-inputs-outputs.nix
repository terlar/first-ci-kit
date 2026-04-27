{ test-lib, ... }:

{
  # --- inputs option at top level ---

  test-top-level-pipeline-input-minimal = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.service = { };
        };
      in
      cfg.inputs.service;
    expected = {
      type = "string";
      required = false;
      default = null;
      description = "";
      options = [ ];
    };
  };

  test-top-level-pipeline-input-full = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.env = {
            type = "choice";
            required = true;
            default = "dev";
            description = "Target environment";
            options = [
              "dev"
              "acc"
              "prd"
            ];
          };
        };
      in
      cfg.inputs.env;
    expected = {
      type = "choice";
      required = true;
      default = "dev";
      description = "Target environment";
      options = [
        "dev"
        "acc"
        "prd"
      ];
    };
  };

  # --- outputs option at top level ---

  test-top-level-pipeline-output-minimal = {
    expr =
      let
        cfg = test-lib.evalConfig {
          outputs.plan = {
            value = "\${{ jobs.plan.outputs.plan }}";
          };
        };
      in
      cfg.outputs.plan;
    expected = {
      value = "\${{ jobs.plan.outputs.plan }}";
      description = "";
    };
  };

  # --- GitHub Actions rendering at top level ---

  test-top-level-pipeline-gha-has-workflow-call-on-inputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.service.type = "string";
        };
      in
      cfg.github-actions.settings.on ? "workflow_call";
    expected = true;
  };

  test-top-level-pipeline-gha-workflow-call-inputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.service = {
            type = "string";
            required = true;
            description = "Service name";
          };
        };
      in
      cfg.github-actions.settings.on.workflow_call.inputs;
    expected = {
      service = {
        type = "string";
        required = true;
        description = "Service name";
      };
    };
  };

  test-top-level-pipeline-gha-workflow-call-outputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          outputs.plan = {
            value = "\${{ jobs.plan.outputs.plan }}";
            description = "Plan output";
          };
        };
      in
      cfg.github-actions.settings.on.workflow_call.outputs;
    expected = {
      plan = {
        value = "\${{ jobs.plan.outputs.plan }}";
        description = "Plan output";
      };
    };
  };

  test-top-level-pipeline-gha-no-workflow-call-without-inputs-outputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          jobs.build.commands = [ "make" ];
        };
      in
      cfg.github-actions.settings ? "on";
    expected = false;
  };

  # --- GitLab CI rendering at top level ---

  test-top-level-pipeline-gitlab-ci-inputs-in-documents = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.env = {
            type = "choice";
            default = "dev";
            options = [
              "dev"
              "prd"
            ];
          };
          jobs.deploy.commands = [ "deploy" ];
        };
      in
      builtins.head cfg.gitlab-ci.fileDocuments;
    expected = {
      spec.inputs.env = {
        default = "dev";
        options = [
          "dev"
          "prd"
        ];
      };
    };
  };

  test-top-level-pipeline-gitlab-ci-no-spec-without-inputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          jobs.build.commands = [ "make" ];
        };
      in
      builtins.length cfg.gitlab-ci.fileDocuments;
    expected = 1;
  };

  test-auto-env-inputs-gha = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          inputs.run_deploy = {
            default = "true";
            description = "Run deploy?";
          };
          jobs.deploy.commands = [ "deploy" ];
        };
      in
      cfg.github-actions.settings.env;
    expected = {
      SERVICE = "\${{ inputs.service }}";
      RUN_DEPLOY = "\${{ inputs.run_deploy }}";
    };
  };

  test-auto-env-inputs-gitlab = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          inputs.run_deploy = {
            default = "true";
            description = "Run deploy?";
          };
          jobs.deploy.commands = [ "deploy" ];
        };
      in
      cfg.jobs.deploy.gitlab-ci.variables;
    expected = {
      SERVICE = "$[[ inputs.service ]]";
      RUN_DEPLOY = "$[[ inputs.run_deploy ]]";
    };
  };

  test-auto-env-inputs-no-pipeline-variables-gitlab = {
    expr =
      let
        cfg = test-lib.evalConfig {
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          jobs.deploy.commands = [ "deploy" ];
        };
      in
      cfg.gitlab-ci.settings ? "variables";
    expected = false;
  };

  test-auto-env-inputs-opt-out-gha = {
    expr =
      let
        cfg = test-lib.evalConfig {
          autoEnvInputs = false;
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          jobs.deploy.commands = [ "deploy" ];
        };
      in
      cfg.github-actions.settings ? "env";
    expected = false;
  };

  test-auto-env-inputs-opt-out-gitlab = {
    expr =
      let
        cfg = test-lib.evalConfig {
          autoEnvInputs = false;
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          jobs.deploy.commands = [ "deploy" ];
        };
      in
      cfg.jobs.deploy.gitlab-ci ? "variables";
    expected = false;
  };
}
