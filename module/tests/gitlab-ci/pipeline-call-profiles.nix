{ test-lib, ... }:

{
  # Profile produces same output as inlining pipelineCall directly
  test-gitlab-ci-pipeline-call-profile-basic = {
    expr = test-lib.eval-gitlab-ci {
      pipelineCallProfiles.tofu = {
        pipeline = "my-pipeline";
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
      };
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCallProfile = "tofu";
    };
    expected = {
      include = [ { local = "ci/templates/my-pipeline.yml"; } ];
    };
  };

  # Profile with rulesInput
  test-gitlab-ci-pipeline-call-profile-rules-input = {
    expr = test-lib.eval-gitlab-ci {
      pipelineCallProfiles.tofu = {
        pipeline = "my-pipeline";
        gitlab-ci = {
          templatePath = "ci/templates/my-pipeline.yml";
          rulesInput = "rules";
        };
      };
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches.default = {
          changes.paths = [ "src/" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCallProfile = "tofu";
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.rules = [
            {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              changes = {
                paths = [ "src/" ];
                compare_to = "$CI_DEFAULT_BRANCH";
              };
            }
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "src/" ];
            }
          ];
        }
      ];
    };
  };

  # Inline pipelineCall.inputs coexist with profile (profile sets defaults, inline wins)
  test-gitlab-ci-pipeline-call-profile-inline-inputs-win = {
    expr = test-lib.eval-gitlab-ci {
      pipelineCallProfiles.tofu = {
        pipeline = "my-pipeline";
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
      };
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        pipelineCallProfile = "tofu";
        pipelineCall.inputs.environment = "prod";
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.environment = "prod";
        }
      ];
    };
  };

  # Inline templatePath overrides profile templatePath
  test-gitlab-ci-pipeline-call-profile-inline-template-path-wins = {
    expr = test-lib.eval-gitlab-ci {
      pipelineCallProfiles.tofu = {
        pipeline = "my-pipeline";
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
      };
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        pipelineCallProfile = "tofu";
        pipelineCall.gitlab-ci.templatePath = "ci/override/template.yml";
      };
    };
    expected = {
      include = [ { local = "ci/override/template.yml"; } ];
    };
  };

  # Profile with null templatePath falls through to pipeline's templatePath
  test-gitlab-ci-pipeline-call-profile-null-template-path-uses-pipeline = {
    expr = test-lib.eval-gitlab-ci {
      pipelineCallProfiles.tofu = {
        pipeline = "my-pipeline";
        # templatePath = null (default) - should fall through to pipeline's templatePath
      };
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCallProfile = "tofu";
    };
    expected = {
      include = [ { local = "ci/templates/my-pipeline.yml"; } ];
    };
  };

  # Profile with pushRulesInput
  test-gitlab-ci-pipeline-call-profile-push-rules-input = {
    expr = test-lib.eval-gitlab-ci {
      pipelineCallProfiles.tofu = {
        pipeline = "my-pipeline";
        gitlab-ci = {
          templatePath = "ci/templates/my-pipeline.yml";
          pushRulesInput = "deploy_rules";
        };
      };
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches.default = {
          changes.paths = [ "src/" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCallProfile = "tofu";
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.deploy_rules = [
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "src/" ];
            }
          ];
        }
      ];
    };
  };

  # Profile with allRulesInput
  test-gitlab-ci-pipeline-call-profile-all-rules-input = {
    expr = test-lib.eval-gitlab-ci {
      pipelineCallProfiles.tofu = {
        pipeline = "my-pipeline";
        gitlab-ci = {
          templatePath = "ci/templates/my-pipeline.yml";
          allRulesInput = "plan_rules";
        };
      };
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches.default = {
          changes.paths = [ "src/" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCallProfile = "tofu";
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.plan_rules = [
            {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              changes = {
                paths = [ "src/" ];
                compare_to = "$CI_DEFAULT_BRANCH";
              };
            }
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "src/" ];
            }
          ];
        }
      ];
    };
  };
}
