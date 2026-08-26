{ test-lib, ... }:

{
  # Basic inline: jobs from child pipeline are placed directly in parent settings.
  test-gitlab-ci-pipeline-call-inline-basic = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.inlinePipelineCalls = true;
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    # No include entry; child job emitted directly.
    expected = {
      do-thing = {
        script = [ "echo hello" ];
      };
    };
  };

  # Inline with string inputs: "$[[ inputs.X ]]" replaced in job names and fields.
  test-gitlab-ci-pipeline-call-inline-string-substitution = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.inlinePipelineCalls = true;
      pipelines.my-pipeline = {
        gitlab-ci = {
          asComponent = true;
          templatePath = "ci/templates/my-pipeline.yml";
          transformJobName = name: "$[[ inputs.service ]]:$[[ inputs.deployment ]]:${name}";
        };
        jobs.plan = {
          commands = [ "plan $SERVICE $DEPLOYMENT" ];
          gitlab-ci.resource_group = "$[[ inputs.service ]]:$[[ inputs.deployment ]]";
        };
      };
      jobs.call.pipelineCall = {
        pipeline = "my-pipeline";
        inputs = {
          service = "my-svc";
          deployment = "dev";
        };
      };
    };
    expected = {
      "my-svc:dev:plan" = {
        script = [ "plan $SERVICE $DEPLOYMENT" ];
        resource_group = "my-svc:dev";
      };
    };
  };

  # Inline with list input (rules): a "$[[ inputs.rules ]]" element in a rules
  # array is spliced with the actual list value.
  test-gitlab-ci-pipeline-call-inline-rules-splice = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.inlinePipelineCalls = true;
      pipelines.my-pipeline = {
        gitlab-ci = {
          asComponent = true;
          templatePath = "ci/templates/my-pipeline.yml";
          transformJobName = name: "$[[ inputs.service ]]:${name}";
        };
        jobs.plan = {
          commands = [ "plan" ];
          gitlab-ci.rules = [
            {
              "if" = "$CI_PIPELINE_SOURCE == 'schedule'";
              when = "never";
            }
            "$[[ inputs.rules ]]"
          ];
        };
      };
      jobs.call = {
        branches.default = {
          changes.paths = [ "services/svc/**/*" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          inputs.service = "svc";
          gitlab-ci.rulesInput = "rules";
        };
      };
    };
    expected = {
      "svc:plan" = {
        script = [ "plan" ];
        rules = [
          {
            "if" = "$CI_PIPELINE_SOURCE == 'schedule'";
            when = "never";
          }
          {
            "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
            changes = {
              paths = [ "services/svc/**/*" ];
              compare_to = "$CI_DEFAULT_BRANCH";
            };
          }
          {
            "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
            changes.paths = [ "services/svc/**/*" ];
          }
        ];
      };
    };
  };

  # Inline: no include entry emitted.
  test-gitlab-ci-pipeline-call-inline-no-include = {
    expr =
      (test-lib.eval-gitlab-ci {
        gitlab-ci.inlinePipelineCalls = true;
        pipelines.my-pipeline = {
          gitlab-ci.asComponent = true;
          gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
          jobs.do-thing.commands = [ "echo hello" ];
        };
        jobs.deploy.pipelineCall.pipeline = "my-pipeline";
      }) ? include;
    expected = false;
  };

  # Default (inlinePipelineCalls = false): pipelineCalls produce include: entries.
  test-gitlab-ci-pipeline-call-default-uses-include = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      include = [ { local = "ci/templates/my-pipeline.yml"; } ];
    };
  };
}
