{ lib, test-lib, ... }:

{
  # generate job appears in parent settings
  test-gitlab-ci-child-pipeline-generate-job-exists = {
    expr =
      lib.pipe
        {
          gitlab-ci.defaultStage = "main";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings ? "generate-child")
        ];
    expected = true;
  };

  # trigger job appears in parent settings
  test-gitlab-ci-child-pipeline-trigger-job-exists = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings ? "trigger-child")
        ];
    expected = true;
  };

  # generate job has correct artifact
  test-gitlab-ci-child-pipeline-generate-job-artifact = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.artifacts)
        ];
    expected = {
      paths = [ "gitlab-ci-child.yml" ];
      expire_in = "1 week";
    };
  };

  # generate job script uses correct build target name
  test-gitlab-ci-child-pipeline-generate-job-script = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.script)
        ];
    expected = [
      "nix build .#ci-pipeline-gitlab-ci--child"
      "cp result gitlab-ci-child.yml"
    ];
  };

  # trigger job references correct artifact
  test-gitlab-ci-child-pipeline-trigger-job-references-artifact = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.trigger)
        ];
    expected = {
      include = [
        {
          artifact = "gitlab-ci-child.yml";
          job = "generate-child";
        }
      ];
    };
  };

  # trigger job is at .post stage when no defaultStage set
  test-gitlab-ci-child-pipeline-trigger-job-stage = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.stage)
        ];
    expected = ".post";
  };

  # trigger job needs the generate job when in the same stage
  test-gitlab-ci-child-pipeline-trigger-job-needs-same-stage = {
    expr =
      lib.pipe
        {
          gitlab-ci.defaultStage = "main";
          pipelines.child = {
            gitlab-ci.defaultStage = "main";
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.needs)
        ];
    expected = [ { job = "generate-child"; } ];
  };

  # trigger job has no needs when at a later stage than generate (e.g. .post)
  test-gitlab-ci-child-pipeline-trigger-job-no-needs-post-stage = {
    expr =
      lib.pipe
        {
          gitlab-ci.defaultStage = "main";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.trigger.stage = ".post";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child ? needs)
        ];
    expected = false;
  };

  # trigger job mirrors generate job rules so it only runs when generate runs
  test-gitlab-ci-child-pipeline-trigger-job-mirrors-generate-rules = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.generateJob.extraRules = [
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              }
            ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.rules)
        ];
    expected = [
      { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH"; }
    ];
  };

  # trigger job has no rules when generate job has no extraRules
  test-gitlab-ci-child-pipeline-trigger-job-no-rules-without-extra-rules = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child ? rules)
        ];
    expected = false;
  };

  # trigger job needs are optional even when generate job has conditional rules
  test-gitlab-ci-child-pipeline-trigger-job-needs-with-extra-rules = {
    expr =
      lib.pipe
        {
          gitlab-ci.defaultStage = "main";
          pipelines.child = {
            gitlab-ci.defaultStage = "main";
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.generateJob.extraRules = [
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              }
            ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.needs)
        ];
    expected = [ { job = "generate-child"; } ];
  };

  # trigger job inherits defaultStage from child
  test-gitlab-ci-child-pipeline-trigger-job-stage-from-default-stage = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            gitlab-ci.defaultStage = "main";
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.stage)
        ];
    expected = "main";
  };

  # trigger job stage can be explicitly overridden
  test-gitlab-ci-child-pipeline-trigger-job-stage-override = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            gitlab-ci.defaultStage = "main";
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.trigger.stage = ".post";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.stage)
        ];
    expected = ".post";
  };

  # strategy: depend passes through
  test-gitlab-ci-child-pipeline-trigger-strategy = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.trigger.strategy = "depend";
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.trigger.strategy)
        ];
    expected = "depend";
  };

  # trigger.forward passes through
  test-gitlab-ci-child-pipeline-trigger-forward = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.trigger.forward = {
              pipeline_variables = true;
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.trigger-child.trigger.forward)
        ];
    expected = {
      pipeline_variables = true;
    };
  };

  # generateJob.extraRules appear in generate job
  test-gitlab-ci-child-pipeline-generate-extra-rules = {
    expr =
      lib.pipe
        {
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
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.rules)
        ];
    expected = [
      {
        "if" = "$GITLAB_USER_EMAIL != $BOT";
        when = "never";
      }
    ];
  };

  # generateJob.beforeScript appear in generate job
  test-gitlab-ci-child-pipeline-generate-before-script = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
            gitlab-ci.dispatch.generateJob.beforeScript = [ "enable-nix-cache" ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.before_script)
        ];
    expected = [ "enable-nix-cache" ];
  };

  # child jobs do NOT appear in parent settings
  test-gitlab-ci-child-pipeline-child-jobs-not-in-parent = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings ? "do-thing")
        ];
    expected = false;
  };

  # generate job inherits defaultStage from parent
  test-gitlab-ci-child-pipeline-generate-job-stage = {
    expr =
      lib.pipe
        {
          gitlab-ci.defaultStage = "main";
          pipelines.child = {
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.stage)
        ];
    expected = "main";
  };

  # gitlab-ci.dispatch.generateJob.image resolved via imageRegistry, relative entry prefixed by
  # gitlab-ci.images.repository
  test-gitlab-ci-child-pipeline-generate-job-image-from-registry = {
    expr =
      lib.pipe
        {
          gitlab-ci.images.repository = "registry.example.com/team";
          imageRegistry = {
            nix = "nix-image:latest";
          };
          pipelines.child = {
            gitlab-ci.dispatch.generateJob.image = "nix";
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.image)
        ];
    expected = "registry.example.com/team/nix-image:latest";
  };

  # gitlab-ci.dispatch.generateJob.image used literally when not in imageRegistry
  test-gitlab-ci-child-pipeline-generate-job-image-literal = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            gitlab-ci.dispatch.generateJob.image = "ubuntu:24.04";
            jobs.do-thing = {
              commands = [ "echo hello" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.image)
        ];
    expected = "ubuntu:24.04";
  };

  # generate job gets needs derived from pipeline needs (job reference)
  test-gitlab-ci-child-pipeline-generate-job-needs-from-job = {
    expr =
      lib.pipe
        {
          jobs.build.commands = [ "make" ];
          pipelines.child = {
            needs = [ { job = "build"; } ];
            jobs.do-thing.commands = [ "echo hello" ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.needs)
        ];
    expected = [ { job = "build"; } ];
  };

  # generate job gets needs derived from pipeline needs (jobSet reference)
  test-gitlab-ci-child-pipeline-generate-job-needs-from-job-set = {
    expr =
      lib.pipe
        {
          jobs.build.commands = [ "make" ];
          jobSets.infra.jobs = [ "build" ];
          pipelines.child = {
            needs = [ { jobSet = "infra"; } ];
            jobs.do-thing.commands = [ "echo hello" ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings.generate-child.needs)
        ];
    expected = [ { job = "build"; } ];
  };

  test-gitlab-ci-child-pipeline-as-component-no-generate-job = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            gitlab-ci.asComponent = true;
            jobs.do-thing.commands = [ "echo hello" ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings ? "generate-child")
        ];
    expected = false;
  };

  test-gitlab-ci-child-pipeline-as-component-no-trigger-job = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            gitlab-ci.asComponent = true;
            jobs.do-thing.commands = [ "echo hello" ];
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.gitlab-ci.settings ? "trigger-child")
        ];
    expected = false;
  };
}
