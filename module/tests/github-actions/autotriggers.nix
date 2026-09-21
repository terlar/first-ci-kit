{ test-lib, ... }:

{
  # By default, on.push/on.pull_request branches are auto-derived from the
  # union of every enabled job's own branch triggers.
  test-github-actions-autotriggers-default-populates-push = {
    expr =
      (test-lib.eval-github-actions {
        jobs.job1 = {
          commands = [ "make test" ];
          branches.default.triggers.onPush = true;
        };
      }).on.push.branches;
    expected = [ "main" ];
  };

  # autoTriggers.enable = false suppresses that auto-population entirely,
  # regardless of what any job's own branch triggers say — for a pipeline
  # that shares jobs with a main CI pipeline but should itself only ever run
  # via schedule/workflow_dispatch.
  test-github-actions-autotriggers-disabled-suppresses-push = {
    expr =
      ((test-lib.eval-github-actions {
        github-actions.autoTriggers.enable = false;
        jobs.job1 = {
          commands = [ "make test" ];
          branches.default.triggers.onPush = true;
        };
      }).on or { }
      )
        ? push;
    expected = false;
  };
}
