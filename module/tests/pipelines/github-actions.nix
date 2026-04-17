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

  # child pipeline github-actions.settings has workflow_call when inputs exist
  test-child-pipeline-gha-has-workflow-call-on-inputs = {
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
            };
          };
        };
      in
      cfg.pipelines.child.github-actions.settings.on ? "workflow_call";
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
      cfg.pipelines.child.github-actions.settings.on.workflow_call.inputs;
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
      cfg.pipelines.child.github-actions.settings.on.workflow_call.outputs;
    expected = {
      plan = {
        value = "\${{ jobs.do-thing.outputs.plan }}";
        description = "Plan output";
      };
    };
  };

  # no workflow_call when no inputs or outputs
  test-child-pipeline-gha-no-workflow-call-without-inputs-outputs = {
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
      cfg.pipelines.child.github-actions.settings ? "on";
    expected = false;
  };

  # github-actions.settings.concurrency can be set directly on child pipeline
  test-child-pipeline-gha-settings-concurrency = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            github-actions.settings.concurrency.group = "deploy";
          };
        };
      in
      cfg.pipelines.child.github-actions.settings.concurrency;
    expected = {
      group = "deploy";
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

  # caller job gets needs derived from pipeline needs (job reference)
  test-child-pipeline-gha-caller-job-needs-from-job = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          jobs.build.commands = [ "make" ];
          pipelines.child = {
            needs = [ { job = "build"; } ];
            jobs.do-thing.commands = [ "echo hello" ];
          };
        };
      in
      cfg.github-actions.settings.jobs.child.needs;
    expected = [ "build" ];
  };

  # caller job gets needs derived from pipeline needs (jobSet reference)
  test-child-pipeline-gha-caller-job-needs-from-job-set = {
    expr =
      let
        cfg = test-lib.evalConfig {
          github-actions.defaultRunsOn = "ubuntu-latest";
          jobs.build.commands = [ "make" ];
          jobSets.infra.jobs = [ "build" ];
          pipelines.child = {
            needs = [ { jobSet = "infra"; } ];
            jobs.do-thing.commands = [ "echo hello" ];
          };
        };
      in
      cfg.github-actions.settings.jobs.child.needs;
    expected = [ "build" ];
  };
}
