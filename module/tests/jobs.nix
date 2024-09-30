{ test-lib, ... }:

{
  test-job-with-needs = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a = { };
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };

    expected = {
      job-a = { };
      job-b = {
        needs = [
          {
            artifacts = true;
            job = "job-a";
            optional = false;
          }
        ];
      };
    };
  };

  test-job-with-image = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.image = "sample-image";
    };

    expected = {
      job.image = "sample-image";
    };
  };

  test-job-with-default-branch-trigger-onMergeRequest = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.branches.default.triggers.onMergeRequest = true;
    };

    expected = {
      job.rules = [ { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-job-with-default-branch-trigger-onMergeRequest-with-paths = {
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

  test-job-with-default-branch-trigger-onPush = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.branches.default.triggers.onPush = true;
    };

    expected = {
      job.rules = [ { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-job-with-default-branch-trigger-onPush-with-paths = {
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

  test-job-with-custom-branch-trigger = {
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

  test-job-with-gitlab-ci-config = {
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
