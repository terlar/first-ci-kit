{ test-lib, ... }:

let
  forceRunAllInput = {
    type = "boolean";
    default = false;
    description = "Skip change detection and run all jobs";
  };
  diffStep =
    {
      DIFF_PATHS,
      run ? builtins.readFile ../../../packages/gha-path-changes/main.bash,
    }:
    {
      id = "diff";
      shell = "bash";
      env = {
        inherit DIFF_PATHS;
        GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
        GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
        FORCE_RUN_ALL = "\${{ inputs.force_run_all }}";
      };
      inherit run;
    };
in
{
  test-github-actions-job-with-changes-paths-gets-changes-job = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";

      jobs.job-a = {
        branches.default = {
          changes.paths = [
            "config/**"
            "terraform/**"
          ];
          triggers.onMergeRequest = true;
        };
      };
    };

    expected = {
      on.pull_request.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-a:config/**|terraform/**"; })
          ];
        };

        job-a = {
          needs = [ "changes" ];
          "if" =
            ''''${{ github.event_name == 'pull_request' && fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
          ];
        };
      };
    };
  };

  # A job without changes.paths does not appear in DIFF_PATHS even when in the same pipeline.
  test-github-actions-job-without-changes-paths-not-in-diff-paths = {
    expr =
      let
        result = test-lib.eval-github-actions {
          github-actions.defaultRunsOn = "ubuntu-latest";

          jobs = {
            job-a = {
              branches.default = {
                changes.paths = [ "config/**" ];
                triggers.onMergeRequest = true;
              };
            };
            job-b = {
              branches.default.triggers.onMergeRequest = true;
            };
          };
        };
        diffPaths = result.jobs.changes.steps;
        diffStepResult = builtins.elemAt diffPaths 1;
      in
      builtins.match ".*job-b.*" diffStepResult.env.DIFF_PATHS;
    expected = null;
  };

  test-github-actions-changes-job-uses-custom-checkout-action = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      github-actions.checkoutAction = "actions/checkout@v5";
      jobs = {
        job-a = {
          branches.default = {
            changes.paths = [ "src/**" ];
            triggers.onMergeRequest = true;
          };
        };
      };
    };
    expected = {
      on.pull_request.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v5";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-a:src/**"; })
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" =
            ''''${{ github.event_name == 'pull_request' && fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v5"; }
          ];
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-optional-need = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = { };
        job-b = {
          branches.default.changes.paths = [ "src/**" ];
          needs = [
            {
              job = "job-a";
              optional = true;
            }
          ];
        };
      };
    };
    expected = {
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-b:src/**"; })
          ];
        };
        job-a = {
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-b = {
          needs = [
            "changes"
            "job-a"
          ];
          "if" =
            ''''${{ always() && fromJSON(needs.changes.outputs.changes)['job-b'] == true && (needs.job-a.result == 'success' || needs.job-a.result == 'skipped') }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-non-optional-need = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = { };
        job-b = {
          branches.default.changes.paths = [ "src/**" ];
          needs = [
            {
              job = "job-a";
              optional = false;
            }
          ];
        };
      };
    };
    expected = {
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-b:src/**"; })
          ];
        };
        job-a = {
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-b = {
          needs = [
            "changes"
            "job-a"
          ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-b'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-colon-in-name = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
      };
      jobs."org:svc-a" = {
        branches.default = {
          changes.paths = [ "src/**" ];
          triggers.onMergeRequest = true;
        };
      };
    };
    expected = {
      on.pull_request.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "org_svc-a:src/**"; })
          ];
        };
        org_svc-a = {
          needs = [ "changes" ];
          "if" =
            ''''${{ github.event_name == 'pull_request' && fromJSON(needs.changes.outputs.changes)['org_svc-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  # A job with triggers but NO own changes.paths must NOT appear in the changes
  # detection map (smoke-test regression: inheriting paths without own paths is wrong).
  test-github-actions-changes-job-without-own-paths-does-not-inherit-from-triggers = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        deploy = {
          branches.default = {
            changes.paths = [ "services/svc/**" ];
            triggers.onMergeRequest = true;
          };
          commands = [ "deploy svc" ];
        };
        smoke-test = {
          # No own changes.paths — should NOT appear in DIFF_PATHS even though it has triggers.
          triggers = [ "deploy" ];
          commands = [ "run-smoke-tests" ];
        };
      };
    };
    expected = {
      on.pull_request.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            # smoke-test must NOT appear here.
            (diffStep { DIFF_PATHS = "deploy:services/svc/**"; })
          ];
        };
        deploy = {
          needs = [ "changes" ];
          "if" =
            ''''${{ github.event_name == 'pull_request' && fromJSON(needs.changes.outputs.changes)['deploy'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "deploy svc"; }
          ];
        };
        smoke-test = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "run-smoke-tests"; }
          ];
        };
      };
    };
  };

  # A job with triggers should inherit changes.paths from its trigger jobs in the
  # changes detection map, mirroring the GitLab CI behaviour in gitlab-ci.nix.
  test-github-actions-changes-job-inherits-paths-from-triggers = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        deploy = {
          branches.default = {
            changes.paths = [ "services/svc/**" ];
            triggers.onMergeRequest = true;
          };
          commands = [ "deploy svc" ];
        };
        post-deploy-test = {
          # Own path (e.g. the test script itself) plus triggers pointing at deploy.
          branches.default.changes.paths = [ "ci/tests/**" ];
          triggers = [ "deploy" ];
          commands = [ "run-tests" ];
        };
      };
    };
    expected = {
      on.pull_request.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            # post-deploy-test must include both its own path and deploy's path.
            (diffStep { DIFF_PATHS = "deploy:services/svc/**\npost-deploy-test:ci/tests/**|services/svc/**"; })
          ];
        };
        deploy = {
          needs = [ "changes" ];
          "if" =
            ''''${{ github.event_name == 'pull_request' && fromJSON(needs.changes.outputs.changes)['deploy'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "deploy svc"; }
          ];
        };
        post-deploy-test = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['post-deploy-test'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "run-tests"; }
          ];
        };
      };
    };
  };

  # changes.paths on a non-default branch key are picked up automatically —
  # no explicit changeBranches config needed.
  test-github-actions-job-with-non-default-branch-changes = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job-a = {
        branches.main = {
          changes.paths = [ "src/**" ];
          triggers.onPush = true;
        };
      };
    };
    expected = {
      on.push.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-a:src/**"; })
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  # branches.default trigger resolves to the configured defaultBranch (default: "main")
  # in the auto-populated on.push.branches / on.pull_request.branches.
  test-github-actions-on-branches-resolved-from-default-branch = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        defaultBranch = "master";
      };
      jobs.job-a = {
        branches.default = {
          changes.paths = [ "src/**" ];
          triggers.onPush = true;
          triggers.onMergeRequest = true;
        };
      };
    };
    expected = {
      on = {
        push.branches = [ "master" ];
        pull_request.branches = [ "master" ];
        workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      };
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-a:src/**"; })
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  # The auto-generated changes job defaults to fetch-depth = 0.
  test-github-actions-changes-job-default-fetch-depth = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job-a.branches.default = {
        changes.paths = [ "src/**" ];
        triggers.onPush = true;
      };
    };
    expected = {
      on.push.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-a:src/**"; })
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  # changesFetchDepth can be overridden.
  test-github-actions-changes-job-custom-fetch-depth = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      github-actions.changesFetchDepth = 50;
      jobs.job-a.branches.default = {
        changes.paths = [ "src/**" ];
        triggers.onPush = true;
      };
    };
    expected = {
      on.push.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 50;
            }
            (diffStep { DIFF_PATHS = "job-a:src/**"; })
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  # A job with only onMergeRequest (no onPush) must restrict its if condition to
  # pull_request events so it does not run on push-to-main pipelines.
  test-github-actions-merge-request-only-job-restricts-to-pull-request-event = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job-a = {
        branches.default = {
          changes.paths = [ "src/**" ];
          triggers.onMergeRequest = true;
        };
      };
    };
    expected = {
      on.pull_request.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-a:src/**"; })
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" =
            ''''${{ github.event_name == 'pull_request' && fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  # A job with both onMergeRequest and onPush must NOT add the event_name guard.
  test-github-actions-push-and-merge-request-job-does-not-restrict-event = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job-a = {
        branches.default = {
          changes.paths = [ "src/**" ];
          triggers = {
            onPush = true;
            onMergeRequest = true;
          };
        };
      };
    };
    expected = {
      on = {
        push.branches = [ "main" ];
        pull_request.branches = [ "main" ];
        workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      };
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            (diffStep { DIFF_PATHS = "job-a:src/**"; })
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };
}
