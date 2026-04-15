{ test-lib, ... }:

{
  # generate job appears in parent settings
  test-child-pipeline-gitlab-ci-generate-job-exists = {
    expr =
      let
        cfg = test-lib.evalConfig {
          gitlab-ci.defaultStage = "main";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings ? "generate-child";
    expected = true;
  };

  # trigger job appears in parent settings
  test-child-pipeline-gitlab-ci-trigger-job-exists = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings ? "trigger-child";
    expected = true;
  };

  # generate job has correct artifact
  test-child-pipeline-gitlab-ci-generate-job-artifact = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings.generate-child.artifacts;
    expected = {
      paths = [ "gitlab-ci-child.yml" ];
      expire_in = "1 week";
    };
  };

  # generate job script uses correct build target name
  test-child-pipeline-gitlab-ci-generate-job-script = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings.generate-child.script;
    expected = [
      "nix build .#ci-pipeline-gitlab-ci--child"
      "cp result gitlab-ci-child.yml"
    ];
  };

  # trigger job references correct artifact
  test-child-pipeline-gitlab-ci-trigger-job-references-artifact = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings.trigger-child.trigger;
    expected = {
      include = [
        {
          artifact = "gitlab-ci-child.yml";
          job = "generate-child";
        }
      ];
    };
  };

  # trigger job is at .post stage
  test-child-pipeline-gitlab-ci-trigger-job-stage = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings.trigger-child.stage;
    expected = ".post";
  };

  # trigger job needs the generate job
  test-child-pipeline-gitlab-ci-trigger-job-needs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings.trigger-child.needs;
    expected = [ { job = "generate-child"; } ];
  };

  # strategy: depend passes through
  test-child-pipeline-gitlab-ci-trigger-strategy = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.trigger.strategy = "depend";
          };
        };
      in
      cfg.gitlab-ci.settings.trigger-child.trigger.strategy;
    expected = "depend";
  };

  # trigger.forward passes through
  test-child-pipeline-gitlab-ci-trigger-forward = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.trigger.forward = {
              pipeline_variables = true;
            };
          };
        };
      in
      cfg.gitlab-ci.settings.trigger-child.trigger.forward;
    expected = {
      pipeline_variables = true;
    };
  };

  # generateJob.extraRules appear in generate job
  test-child-pipeline-gitlab-ci-generate-extra-rules = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.generateJob.extraRules = [
              {
                "if" = "$GITLAB_USER_EMAIL != $BOT";
                when = "never";
              }
            ];
          };
        };
      in
      cfg.gitlab-ci.settings.generate-child.rules;
    expected = [
      {
        "if" = "$GITLAB_USER_EMAIL != $BOT";
        when = "never";
      }
    ];
  };

  # generateJob.beforeScript appear in generate job
  test-child-pipeline-gitlab-ci-generate-before-script = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.generateJob.beforeScript = [ "enable-nix-cache" ];
          };
        };
      in
      cfg.gitlab-ci.settings.generate-child.before_script;
    expected = [ "enable-nix-cache" ];
  };

  # child jobs do NOT appear in parent settings
  test-child-pipeline-gitlab-ci-child-jobs-not-in-parent = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings ? "do-thing";
    expected = false;
  };

  # generate job inherits defaultStage from parent
  test-child-pipeline-gitlab-ci-generate-job-stage = {
    expr =
      let
        cfg = test-lib.evalConfig {
          gitlab-ci.defaultStage = "main";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings.generate-child.stage;
    expected = "main";
  };

  # tags set image via imageRegistry
  test-child-pipeline-gitlab-ci-generate-job-image = {
    expr =
      let
        cfg = test-lib.evalConfig {
          imageRegistry = {
            "profile:nix" = "nix-image:latest";
          };
          pipelines.child = {
            tags = [ "profile:nix" ];
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        };
      in
      cfg.gitlab-ci.settings.generate-child.image;
    expected = "nix-image:latest";
  };
}
