{ test-lib, ... }:

{
  test-github-jobs = {
    expr = test-lib.eval-github-actions {
      jobs.job1 = {
        checkout = true;
        commands = [ "echo 'Run your script here'" ];
      };
    };
    expected = {
      jobs.job1 = {
        steps = [
          { uses = "actions/checkout@v4"; }
          { run = "echo 'Run your script here'"; }
        ];
      };
    };
  };

  test-gitlab-jobs = {
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

  test-gitlab-jobs-enable = {
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

  test-gitlab-job-with-needs = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a = { };
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };

    expected = {
      job-a = { };
      job-b.needs = [
        {
          artifacts = true;
          job = "job-a";
          optional = false;
        }
      ];
    };
  };

  test-gitlab-job-with-image = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.image = "sample-image";
    };

    expected = {
      job.image = "sample-image";
    };
  };

  test-gitlab-job-with-default-branch-trigger-onMergeRequest = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.branches.default.triggers.onMergeRequest = true;
    };

    expected = {
      job.rules = [ { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-gitlab-job-with-default-branch-trigger-onMergeRequest-with-paths = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job = {
        branches.default = {
          changes.paths = [ "a-path" ];
          triggers.onMergeRequest = true;
        };
      };
    };

    expected = {
      job.rules = [
        {
          "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
          changes = {
            paths = [ "a-path" ];
            compare_to = "refs/heads/$CI_DEFAULT_BRANCH";
          };
        }
      ];
    };
  };

  test-gitlab-job-with-default-branch-trigger-onPush = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.branches.default.triggers.onPush = true;
    };

    expected = {
      job.rules = [ { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-gitlab-job-with-default-branch-trigger-onPush-with-paths = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job = {
        branches.default = {
          changes.paths = [ "a-path" ];
          triggers.onPush = true;
        };
      };
    };

    expected = {
      job.rules = [
        {
          "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
          changes = {
            paths = [ "a-path" ];
          };
        }
      ];
    };
  };

  test-gitlab-job-with-custom-branch-trigger = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job = {
        branches.a-branch = {
          changes.paths = [ "a-path" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
      };
    };

    expected = {
      job.rules = [
        {
          "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == 'a-branch'";
          changes = {
            compare_to = "refs/heads/a-branch";
            paths = [ "a-path" ];
          };
        }
        {
          changes.paths = [ "a-path" ];
          "if" = "$CI_COMMIT_BRANCH == 'a-branch'";
        }
      ];
    };
  };

  test-gitlab-job-with-gitlab-ci-config = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job = {
        gitlab-ci.environment = "test";
      };
    };

    expected = {
      job.environment = "test";
    };
  };
}
