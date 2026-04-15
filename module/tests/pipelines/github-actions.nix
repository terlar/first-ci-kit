{ test-lib, ... }:

{
  # caller job appears in parent github-actions.settings.jobs
  test-child-pipeline-gha-caller-job-exists = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.github-actions.settings.jobs ? "child";
    expected = true;
  };

  # caller job has correct uses path
  test-child-pipeline-gha-caller-job-uses = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.github-actions.settings.jobs.child.uses;
    expected = "./.github/workflows/child.yml";
  };

  # caller job has secrets: inherit
  test-child-pipeline-gha-caller-job-secrets = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.github-actions.settings.jobs.child.secrets;
    expected = "inherit";
  };

  # child jobs do NOT appear in parent settings.jobs
  test-child-pipeline-gha-child-jobs-not-in-parent = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.github-actions.settings.jobs ? "do-thing";
    expected = false;
  };

  # reusableWorkflowSettings contains child entry
  test-child-pipeline-gha-reusable-workflow-settings = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.github-actions.reusableWorkflowSettings ? "child";
    expected = true;
  };

  # workflow_call.inputs populated from child inputs
  test-child-pipeline-gha-workflow-call-inputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            inputs.service = {
              type = "string";
              required = true;
              description = "Service name";
            };
          };
        };
      in
      cfg.github-actions.reusableWorkflowSettings.child.on.workflow_call.inputs;
    expected = {
      service = {
        type = "string";
        required = true;
        description = "Service name";
      };
    };
  };

  # workflow_call.outputs populated from child outputs
  test-child-pipeline-gha-workflow-call-outputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            outputs.plan = {
              value = "\${{ jobs.do-thing.outputs.plan }}";
              description = "Plan output";
            };
          };
        };
      in
      cfg.github-actions.reusableWorkflowSettings.child.on.workflow_call.outputs;
    expected = {
      plan = {
        value = "\${{ jobs.do-thing.outputs.plan }}";
        description = "Plan output";
      };
    };
  };

  # callerIf sets if on caller job
  test-child-pipeline-gha-caller-if = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            github-actions.dispatch.callerIf = "github.event_name == 'push'";
          };
        };
      in
      cfg.github-actions.settings.jobs.child."if";
    expected = "github.event_name == 'push'";
  };

  # github-actions.dispatch.settings merges into reusable workflow root
  test-child-pipeline-gha-dispatch-settings-merge = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            github-actions.dispatch.settings = {
              concurrency.group = "deploy";
            };
          };
        };
      in
      cfg.github-actions.reusableWorkflowSettings.child.concurrency;
    expected = {
      group = "deploy";
    };
  };
}
