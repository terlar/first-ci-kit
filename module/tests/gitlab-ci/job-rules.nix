{ lib, test-lib, ... }:

{
  test-gitlab-ci-job-with-default-branch-trigger-on-merge-request = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.branches.default.triggers.onMergeRequest = true;
    };

    expected = {
      job.rules = [ { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-gitlab-ci-job-with-default-branch-trigger-on-merge-request-with-paths = {
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
            compare_to = "$CI_DEFAULT_BRANCH";
          };
        }
      ];
    };
  };

  test-gitlab-ci-job-with-default-branch-trigger-on-push = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job.branches.default.triggers.onPush = true;
    };

    expected = {
      job.rules = [ { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-gitlab-ci-job-with-default-branch-trigger-on-push-with-paths = {
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

  test-gitlab-ci-job-custom-rules-prepend-before-trigger-rules = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job = {
        branches.default.triggers.onMergeRequest = true;
        gitlab-ci.rules = [
          {
            "if" = "$CI_PIPELINE_SOURCE == 'schedule'";
            where = "never";
          }
        ];
      };
    };

    expected = {
      job.rules = [
        {
          "if" = "$CI_PIPELINE_SOURCE == 'schedule'";
          where = "never";
        }
        { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH"; }
      ];
    };
  };

  test-gitlab-ci-job-with-both-merge-request-and-push-triggers = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job = {
        branches.default = {
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
      };
    };

    expected = {
      job.rules = [
        { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH"; }
        { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; }
      ];
    };
  };

  test-gitlab-ci-job-with-custom-branch-trigger = {
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
            compare_to = "a-branch";
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

  test-gitlab-ci-job-triggers-filter-unknown-job = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        job-b = {
          triggers = [ "non-existent-job" ];
          branches.default.triggers.onPush = true;
        };
      };
    };
    expected = {
      job-b.rules = [ { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-gitlab-ci-job-triggers-filter-disabled-job = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        job-a = {
          enable = false;
          branches.default = {
            changes.paths = [ "a-path" ];
            triggers.onPush = true;
          };
        };
        job-b = {
          triggers = [ "job-a" ];
          branches.default.triggers.onPush = true;
        };
      };
    };
    expected = {
      job-b.rules = [ { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  test-gitlab-ci-job-triggers-filter-per-backend-disabled-job = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        job-a = {
          gitlab-ci.enable = false;
          branches.default = {
            changes.paths = [ "a-path" ];
            triggers.onPush = true;
          };
        };
        job-b = {
          triggers = [ "job-a" ];
          branches.default.triggers.onPush = true;
        };
      };
    };
    expected = {
      job-b.rules = [ { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; } ];
    };
  };

  # A job with no own changes.paths but with triggers inherits trigger job paths in rules.
  test-gitlab-ci-changes-job-without-own-paths-inherits-from-triggers = {
    expr =
      lib.pipe
        {
          jobs = {
            deploy = {
              branches.default = {
                changes.paths = [ "services/svc/**" ];
                triggers.onMergeRequest = true;
              };
              commands = [ "deploy svc" ];
            };
            smoke-test = {
              # No own changes.paths — inherits deploy's paths via triggers.
              triggers = [ "deploy" ];
              branches.default.triggers.onMergeRequest = true;
              commands = [ "run-smoke-tests" ];
            };
          };
        }
        [
          test-lib.eval-gitlab-ci
          (lib.mapAttrs (_: lib.getAttrs [ "rules" ]))
        ];
    expected = {
      deploy.rules = [
        {
          "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
          changes = {
            paths = [ "services/svc/**" ];
            compare_to = "$CI_DEFAULT_BRANCH";
          };
        }
      ];
      smoke-test.rules = [
        {
          "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
          changes = {
            paths = [ "services/svc/**" ];
            compare_to = "$CI_DEFAULT_BRANCH";
          };
        }
      ];
    };
  };

  # A job with own changes.paths and triggers should inherit trigger job paths in rules.
  test-gitlab-ci-changes-job-inherits-paths-from-triggers = {
    expr =
      lib.pipe
        {
          jobs = {
            deploy = {
              branches.default = {
                changes.paths = [ "services/svc/**" ];
                triggers.onMergeRequest = true;
                triggers.onPush = true;
              };
              commands = [ "deploy svc" ];
            };
            post-deploy-test = {
              # Own path plus triggers pointing at deploy — should combine paths.
              branches.default = {
                changes.paths = [ "ci/tests/**" ];
                triggers.onMergeRequest = true;
                triggers.onPush = true;
              };
              triggers = [ "deploy" ];
              commands = [ "run-tests" ];
            };
          };
        }
        [
          test-lib.eval-gitlab-ci
          (lib.mapAttrs (_: lib.getAttrs [ "rules" ]))
        ];
    expected = {
      deploy.rules = [
        {
          "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
          changes = {
            paths = [ "services/svc/**" ];
            compare_to = "$CI_DEFAULT_BRANCH";
          };
        }
        {
          "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
          changes.paths = [ "services/svc/**" ];
        }
      ];
      post-deploy-test.rules = [
        {
          "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
          changes = {
            paths = [
              "ci/tests/**"
              "services/svc/**"
            ];
            compare_to = "$CI_DEFAULT_BRANCH";
          };
        }
        {
          "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
          changes.paths = [
            "ci/tests/**"
            "services/svc/**"
          ];
        }
      ];
    };
  };
}
