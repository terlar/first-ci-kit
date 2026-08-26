{ test-lib, ... }:

{
  test-gitlab-ci-job-basic = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job1 = {
        checkout = true;
        commands = [ "echo 'Run your script here'" ];
      };
    };
    expected = {
      job1 = {
        script = [ "echo 'Run your script here'" ];
      };
    };
  };

  test-gitlab-ci-job-transform-name = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.transformJobName = builtins.replaceStrings [ "_" ] [ ":" ];
      jobs = {
        "job_a" = { };
        "job_b".needs = [
          { job = "job_a"; }
        ];
      };
    };
    expected = {
      "job:a" = { };
      "job:b".needs = [
        {
          artifacts = true;
          job = "job:a";
          optional = false;
        }
      ];
    };
  };

  test-gitlab-ci-job-enable = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        job-a = { };
        job-b.enable = false;
        job-c.needs = [
          { job = "job-a"; }
          { job = "job-b"; }
        ];
      };
    };
    expected = {
      job-a = { };
      job-c.needs = [
        {
          artifacts = true;
          job = "job-a";
          optional = false;
        }
      ];
    };
  };

  test-gitlab-ci-job-per-backend-disable = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.defaultStage = "test";
      jobs = {
        job-a = {
          commands = [ "echo job-a" ];
        };
        job-b = {
          commands = [ "echo job-b" ];
          gitlab-ci.enable = false;
        };
        job-c = {
          commands = [ "echo job-c" ];
          needs = [ { job = "job-b"; } ];
        };
      };
    };
    expected = {
      job-a = {
        stage = "test";
        script = [ "echo job-a" ];
      };
      job-c = {
        stage = "test";
        script = [ "echo job-c" ];
      };
    };
  };

  test-gitlab-ci-job-global-disable-overrides-per-backend-enable = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.defaultStage = "test";
      jobs = {
        job-a = {
          commands = [ "echo job-a" ];
        };
        job-b = {
          commands = [ "echo job-b" ];
          enable = false;
          gitlab-ci.enable = true;
        };
      };
    };
    expected = {
      job-a = {
        stage = "test";
        script = [ "echo job-a" ];
      };
    };
  };

  test-gitlab-ci-job-default-stage = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci = {
        settings.stages = [ "main" ];
        defaultStage = "main";
      };

      jobs.job1 = {
        commands = [ "echo 'Run your script here'" ];
      };
    };
    expected = {
      stages = [ "main" ];
      job1 = {
        stage = "main";
        script = [ "echo 'Run your script here'" ];
      };
    };
  };

  test-gitlab-ci-job-with-image = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.image = "sample-image";
    };

    expected = {
      job.image = "sample-image";
    };
  };

  test-gitlab-ci-job-with-image-from-image-registry = {
    expr = test-lib.eval-gitlab-ci {
      imageRegistry.sample-image = "registry/repository/sample-image:tag";
      jobs.job.image = "sample-image";
    };

    expected = {
      job.image = "registry/repository/sample-image:tag";
    };
  };

  test-gitlab-ci-job-image-opt-out = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.images.enable = false;
      jobs.job.image = "sample-image";
    };

    expected = {
      job = { };
    };
  };

  test-gitlab-ci-job-with-image-from-repository = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.images.repository = "registry.example.com/team";
      imageRegistry = {
        tofu = "tofu:1.9";
        external = "ghcr.io/org/external:latest";
      };
      jobs.job.image = "tofu";
    };

    expected = {
      job.image = "registry.example.com/team/tofu:1.9";
    };
  };

  # Direct job image references are never prefixed, even when a repository is set
  test-gitlab-ci-job-with-direct-image-ignores-repository = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.images.repository = "registry.example.com/team";
      jobs.job.image = "ubuntu:24.04";
    };

    expected = {
      job.image = "ubuntu:24.04";
    };
  };

  test-gitlab-ci-job-with-gitlab-ci-config = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job = {
        gitlab-ci.environment = "test";
      };
    };

    expected = {
      job.environment = "test";
    };
  };

  # fetchDepth = 0 sets GIT_DEPTH = "0" in the job variables.
  test-gitlab-ci-job-fetch-depth = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job1 = {
        fetchDepth = 0;
        commands = [ "git log" ];
      };
    };
    expected = {
      job1 = {
        script = [ "git log" ];
        variables.GIT_DEPTH = "0";
      };
    };
  };

  # fetchDepth = null (default) does not set GIT_DEPTH.
  test-gitlab-ci-job-fetch-depth-null-omits-variable = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job1.commands = [ "echo hi" ];
    };
    expected = {
      job1.script = [ "echo hi" ];
    };
  };
}
