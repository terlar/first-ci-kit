{
  first-ci-kit.pipelines.default = {
    pipeline = {
      gitlab-ci = {
        defaultStage = "main";
        settings = {
          stages = [ "main" ];
          workflow.rules = [
            { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED"; }
            { "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"; }
          ];
        };
      };

      github-actions.settings = {
        name = "CI";
        on.push = {
          branches = [ "main" ];
        };
        on.pull_request = {
          branches = [ "main" ];
        };
      };
    };

    jobs = {
      test = {
        github-actions.runs-on = "ubuntu-latest";
        commands = [
          ''echo "It's working, it's working!"''
        ];
      };
    };
  };
}
