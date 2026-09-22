{ test-lib, ... }:

{
  # triggers.onDemand = true wires ON_DEMAND_BASE_REF into the changes job env
  test-github-actions-on-demand-wires-base-ref = {
    expr =
      let
        result = test-lib.eval-github-actions {
          github-actions.defaultRunsOn = "ubuntu-latest";
          jobs.job-a.branches.production = {
            changes.paths = [ "src/**" ];
            triggers.onDemand = true;
          };
        };
      in
      result.jobs.changes.steps;
    expected = [
      {
        uses = "actions/checkout@v7";
        "with"."fetch-depth" = 0;
      }
      {
        id = "diff";
        shell = "bash";
        env = {
          DIFF_PATHS = "job-a:src/**";
          GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
          GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
          FORCE_RUN_ALL = "\${{ inputs.force_run_all }}";
          ON_DEMAND_BASE_REF = "production";
        };
        run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
      }
    ];
  };

  # "default" onDemand branch key resolves to github-actions.defaultBranch
  test-github-actions-on-demand-resolves-default-branch = {
    expr =
      let
        result = test-lib.eval-github-actions {
          github-actions.defaultRunsOn = "ubuntu-latest";
          github-actions.defaultBranch = "trunk";
          jobs.job-a.branches.default = {
            changes.paths = [ "src/**" ];
            triggers.onDemand = true;
          };
        };
      in
      result.jobs.changes.steps;
    expected = [
      {
        uses = "actions/checkout@v7";
        "with"."fetch-depth" = 0;
      }
      {
        id = "diff";
        shell = "bash";
        env = {
          DIFF_PATHS = "job-a:src/**";
          GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
          GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
          FORCE_RUN_ALL = "\${{ inputs.force_run_all }}";
          ON_DEMAND_BASE_REF = "trunk";
        };
        run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
      }
    ];
  };

  # no onDemand branches configured -> no ON_DEMAND_BASE_REF env var
  test-github-actions-no-on-demand-no-base-ref = {
    expr =
      let
        result = test-lib.eval-github-actions {
          github-actions.defaultRunsOn = "ubuntu-latest";
          jobs.job-a.branches.default = {
            changes.paths = [ "src/**" ];
            triggers.onPush = true;
          };
        };
      in
      result.jobs.changes.steps;
    expected = [
      {
        uses = "actions/checkout@v7";
        "with"."fetch-depth" = 0;
      }
      {
        id = "diff";
        shell = "bash";
        env = {
          DIFF_PATHS = "job-a:src/**";
          GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
          GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
          FORCE_RUN_ALL = "\${{ inputs.force_run_all }}";
        };
        run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
      }
    ];
  };

  # two jobs disagreeing on their onDemand branch trips the single-baseline assertion
  #
  # builtins.tryEval only forces to WHNF, and eval-github-actions returns a
  # lazily-merged attrset, so the assert (buried in
  # jobs.changes.steps.*.env) wouldn't fire until something deeply forces
  # the result later (outside the tryEval). builtins.deepSeq forces it here
  # instead, so tryEval actually catches the throw.
  test-github-actions-on-demand-conflicting-branches-asserts = {
    expr = builtins.tryEval (
      builtins.deepSeq (test-lib.eval-github-actions {
        github-actions.defaultRunsOn = "ubuntu-latest";
        jobs.job-a.branches.production = {
          changes.paths = [ "src/**" ];
          triggers.onDemand = true;
        };
        jobs.job-b.branches.staging = {
          changes.paths = [ "other/**" ];
          triggers.onDemand = true;
        };
      }) true
    );
    expected = {
      success = false;
      value = false;
    };
  };
}
