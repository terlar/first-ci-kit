{ test-lib, ... }:

let
  forceRunAllInput = {
    type = "boolean";
    default = false;
    description = "Skip change detection and run all jobs";
  };
in
{
  # When summaryJob.enable = true, a summary job is generated that needs all
  # other jobs (including changes) and always() runs last.
  test-github-actions-summary-job-basic = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        summaryJob.enable = true;
      };
      jobs = {
        deploy = {
          branches.default = {
            changes.paths = [ "services/svc/**" ];
            triggers.onMergeRequest = true;
          };
          commands = [ "deploy svc" ];
        };
        test = {
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
            {
              id = "diff";
              shell = "bash";
              env = {
                DIFF_PATHS = "deploy:services/svc/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
                FORCE_RUN_ALL = "\${{ inputs.force_run_all }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
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
        test = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "run-tests"; }
          ];
        };
        summary = {
          "if" = "\${{ always() }}";
          needs = [
            "changes"
            "deploy"
            "test"
          ];
          permissions.actions = "read";
          runs-on = "ubuntu-latest";
          steps = [
            {
              shell = "bash";
              env = {
                GH_TOKEN = "\${{ github.token }}";
                SUMMARY_JOB_NAME = "summary";
              };
              run = builtins.readFile ../../../packages/gha-job-summary/main.bash;
            }
          ];
        };
      };
    };
  };

  # Custom summaryJob.name is honoured.
  test-github-actions-summary-job-custom-name = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        summaryJob = {
          enable = true;
          name = "workflow-summary";
        };
      };
      jobs.build.commands = [ "make build" ];
    };
    expected = {
      jobs = {
        build = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "make build"; }
          ];
        };
        workflow-summary = {
          "if" = "\${{ always() }}";
          needs = [ "build" ];
          permissions.actions = "read";
          runs-on = "ubuntu-latest";
          steps = [
            {
              shell = "bash";
              env = {
                GH_TOKEN = "\${{ github.token }}";
                SUMMARY_JOB_NAME = "workflow-summary";
              };
              run = builtins.readFile ../../../packages/gha-job-summary/main.bash;
            }
          ];
        };
      };
    };
  };
}
