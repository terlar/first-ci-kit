{ lib, test-lib, ... }:

{
  # caller job has correct uses path
  test-github-actions-child-pipeline-caller-job-uses = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs.child.uses)
        ];
    expected = "./.github/workflows/child.yml";
  };

  # caller job has secrets: inherit
  test-github-actions-child-pipeline-caller-job-secrets = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs.child.secrets)
        ];
    expected = "inherit";
  };

  # child jobs do NOT appear in parent settings.jobs
  test-github-actions-child-pipeline-child-jobs-not-in-parent = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs ? "do-thing")
        ];
    expected = false;
  };

  # child pipeline github-actions.settings has workflow_call when inputs exist
  test-github-actions-child-pipeline-has-workflow-call-on-inputs = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            inputs.service = {
              type = "string";
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.github-actions.settings.on ? "workflow_call")
        ];
    expected = true;
  };

  # workflow_call.inputs populated from child inputs
  test-github-actions-child-pipeline-workflow-call-inputs = {
    expr =
      lib.pipe
        {
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
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.github-actions.settings.on.workflow_call.inputs)
        ];
    expected = {
      service = {
        type = "string";
        required = true;
        description = "Service name";
      };
    };
  };

  # workflow_call.outputs populated from child outputs
  test-github-actions-child-pipeline-workflow-call-outputs = {
    expr =
      lib.pipe
        {
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
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.github-actions.settings.on.workflow_call.outputs)
        ];
    expected = {
      plan = {
        value = "\${{ jobs.do-thing.outputs.plan }}";
        description = "Plan output";
      };
    };
  };

  # no workflow_call when no inputs or outputs
  test-github-actions-child-pipeline-no-workflow-call-without-inputs-outputs = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.github-actions.settings ? "on")
        ];
    expected = false;
  };

  # github-actions.settings.concurrency can be set directly on child pipeline
  test-github-actions-child-pipeline-settings-concurrency = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            github-actions.settings.concurrency.group = "deploy";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.github-actions.settings.concurrency)
        ];
    expected = {
      group = "deploy";
    };
  };

  # callerIf sets if on caller job
  test-github-actions-child-pipeline-caller-if = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            github-actions.dispatch.callerIf = "github.event_name == 'push'";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs.child."if")
        ];
    expected = "github.event_name == 'push'";
  };

  # caller job gets needs derived from pipeline needs (job reference)
  test-github-actions-child-pipeline-caller-job-needs-from-job = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          jobs.build.commands = [ "make" ];
          pipelines.child = {
            needs = [ { job = "build"; } ];
            jobs.do-thing.commands = [ "echo hello" ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs.child.needs)
        ];
    expected = [ "build" ];
  };

  # caller job gets needs derived from pipeline needs (jobSet reference)
  test-github-actions-child-pipeline-caller-job-needs-from-job-set = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          jobs.build.commands = [ "make" ];
          jobSets.infra.jobs = [ "build" ];
          pipelines.child = {
            needs = [ { jobSet = "infra"; } ];
            jobs.do-thing.commands = [ "echo hello" ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs.child.needs)
        ];
    expected = [ "build" ];
  };
}
