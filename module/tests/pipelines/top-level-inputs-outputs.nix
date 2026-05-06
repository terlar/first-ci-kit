{ lib, test-lib, ... }:

{
  # --- inputs option at top level ---

  test-top-level-pipeline-input-minimal = {
    expr =
      lib.pipe
        {
          inputs.service = { };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.inputs.service)
        ];
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
      lib.pipe
        {
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
        }
        [
          test-lib.evalConfig
          (cfg: cfg.inputs.env)
        ];
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
      lib.pipe
        {
          outputs.plan = {
            value = "\${{ jobs.plan.outputs.plan }}";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.outputs.plan)
        ];
    expected = {
      value = "\${{ jobs.plan.outputs.plan }}";
      description = "";
    };
  };

  # --- GitHub Actions rendering at top level ---

  test-top-level-pipeline-gha-has-workflow-call-on-inputs = {
    expr =
      lib.pipe
        {
          inputs.service.type = "string";
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.on ? "workflow_call")
        ];
    expected = true;
  };

  test-top-level-pipeline-gha-workflow-call-inputs = {
    expr =
      lib.pipe
        {
          inputs.service = {
            type = "string";
            required = true;
            description = "Service name";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.on.workflow_call.inputs)
        ];
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
      lib.pipe
        {
          outputs.plan = {
            value = "\${{ jobs.plan.outputs.plan }}";
            description = "Plan output";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.on.workflow_call.outputs)
        ];
    expected = {
      plan = {
        value = "\${{ jobs.plan.outputs.plan }}";
        description = "Plan output";
      };
    };
  };

  test-top-level-pipeline-gha-no-workflow-call-without-inputs-outputs = {
    expr =
      lib.pipe
        {
          jobs.build.commands = [ "make" ];
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings ? "on")
        ];
    expected = false;
  };

  # --- GitLab CI rendering at top level ---

  test-top-level-pipeline-gitlab-ci-inputs-in-documents = {
    expr =
      lib.pipe
        {
          inputs.env = {
            type = "choice";
            default = "dev";
            options = [
              "dev"
              "prd"
            ];
          };
          jobs.deploy.commands = [ "deploy" ];
        }
        [
          test-lib.evalConfig
          (cfg: builtins.head cfg.gitlab-ci.fileDocuments)
        ];
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
      lib.pipe
        {
          jobs.build.commands = [ "make" ];
        }
        [
          test-lib.evalConfig
          (cfg: builtins.length cfg.gitlab-ci.fileDocuments)
        ];
    expected = 1;
  };

  test-github-actions-auto-env-inputs = {
    expr =
      lib.pipe
        {
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          inputs.run_deploy = {
            default = "true";
            description = "Run deploy?";
          };
          jobs.deploy.commands = [ "deploy" ];
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.env)
        ];
    expected = {
      SERVICE = "\${{ inputs.service }}";
      RUN_DEPLOY = "\${{ inputs.run_deploy }}";
    };
  };

  test-gitlab-ci-auto-env-inputs = {
    expr =
      lib.pipe
        {
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          inputs.run_deploy = {
            default = "true";
            description = "Run deploy?";
          };
          jobs.deploy.commands = [ "deploy" ];
        }
        [
          test-lib.evalConfig
          (cfg: cfg.jobs.deploy.gitlab-ci.variables)
        ];
    expected = {
      SERVICE = "$[[ inputs.service ]]";
      RUN_DEPLOY = "$[[ inputs.run_deploy ]]";
    };
  };

  test-gitlab-ci-auto-env-inputs-no-pipeline-variables = {
    expr =
      lib.pipe
        {
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          jobs.deploy.commands = [ "deploy" ];
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings ? "variables")
        ];
    expected = false;
  };

  test-github-actions-auto-env-inputs-opt-out = {
    expr =
      lib.pipe
        {
          autoEnvInputs = false;
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          jobs.deploy.commands = [ "deploy" ];
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings ? "env")
        ];
    expected = false;
  };

  test-gitlab-ci-auto-env-inputs-opt-out = {
    expr =
      lib.pipe
        {
          autoEnvInputs = false;
          inputs.service = {
            required = true;
            description = "Service name.";
          };
          jobs.deploy.commands = [ "deploy" ];
        }
        [
          test-lib.evalConfig
          (cfg: cfg.jobs.deploy.gitlab-ci ? "variables")
        ];
    expected = false;
  };
}
