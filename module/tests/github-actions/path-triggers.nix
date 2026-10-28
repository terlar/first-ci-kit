{ test-lib, ... }:

{
  # pathTriggers is opt-in: without enabling it, on.push/on.pull_request never
  # gain a `paths` filter even when jobs declare changes.paths.
  test-github-actions-path-triggers-disabled-by-default = {
    expr =
      (test-lib.eval-github-actions {
        jobs.job1.branches.default = {
          triggers.onPush = true;
          changes.paths = [ "a/**" ];
        };
      }).on.push
        ? paths;
    expected = false;
  };

  # Enabled: on.push.paths / on.pull_request.paths are the union of every
  # enabled job's branches.*.changes.paths, restricted to branches that
  # trigger that event.
  test-github-actions-path-triggers-union = {
    expr =
      let
        result = test-lib.eval-github-actions {
          github-actions.pathTriggers.enable = true;
          jobs = {
            job1.branches.default = {
              triggers.onPush = true;
              changes.paths = [ "a/**" ];
            };
            job2.branches.release = {
              triggers = {
                onPush = true;
                onMergeRequest = true;
              };
              changes.paths = [
                "b/*"
                "a/**"
              ];
            };
          };
        };
      in
      {
        push = result.on.push.paths;
        pull_request = result.on.pull_request.paths;
      };
    expected = {
      push = [
        "a/**"
        "b/*"
      ];
      pull_request = [
        "a/**"
        "b/*"
      ];
    };
  };

  # A disabled job's changes.paths are excluded from the union.
  test-github-actions-path-triggers-skips-disabled-jobs = {
    expr =
      (test-lib.eval-github-actions {
        github-actions.pathTriggers.enable = true;
        jobs = {
          job1.branches.default = {
            triggers.onPush = true;
            changes.paths = [ "a/**" ];
          };
          job2 = {
            enable = false;
            branches.default = {
              triggers.onPush = true;
              changes.paths = [ "b/*" ];
            };
          };
        };
      }).on.push.paths;
    expected = [ "a/**" ];
  };

  # pathTriggers.extraPaths is folded into the union alongside job paths.
  test-github-actions-path-triggers-extra-paths = {
    expr =
      (test-lib.eval-github-actions {
        github-actions.pathTriggers = {
          enable = true;
          extraPaths = [ "x.nix" ];
        };
        jobs.job1.branches.default = {
          triggers.onPush = true;
          changes.paths = [ "a/**" ];
        };
      }).on.push.paths;
    expected = [
      "a/**"
      "x.nix"
    ];
  };
}
