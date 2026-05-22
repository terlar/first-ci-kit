{ test-lib, ... }:

{
  # templatesPath defaults to "gitlab-templates"
  test-gitlab-ci-templates-path-default = {
    expr = (test-lib.evalConfig { }).gitlab-ci.templatesPath;
    expected = "gitlab-templates";
  };

  # templatesPath can be overridden
  test-gitlab-ci-templates-path-custom = {
    expr = (test-lib.evalConfig { gitlab-ci.templatesPath = "ci/components"; }).gitlab-ci.templatesPath;
    expected = "ci/components";
  };

  # pipelineCall resolves templatePath from allPipelines (top-level sibling pipeline)
  test-gitlab-ci-pipeline-call-template-path-from-all-pipelines = {
    expr = test-lib.eval-gitlab-ci [
      {
        _module.args.allPipelines = {
          infra.gitlab-ci.templatePath = "gitlab-templates/infra/template.yml";
        };
      }
      { jobs.deploy.pipelineCall.pipeline = "infra"; }
    ];
    expected = {
      include = [ { local = "gitlab-templates/infra/template.yml"; } ];
    };
  };

  # per-job templatePath wins over allPipelines
  test-gitlab-ci-pipeline-call-per-job-template-path-overrides-all-pipelines = {
    expr = test-lib.eval-gitlab-ci [
      {
        _module.args.allPipelines = {
          infra.gitlab-ci.templatePath = "gitlab-templates/infra/template.yml";
        };
      }
      {
        jobs.deploy.pipelineCall = {
          pipeline = "infra";
          gitlab-ci.templatePath = "ci/override/infra.yml";
        };
      }
    ];
    expected = {
      include = [ { local = "ci/override/infra.yml"; } ];
    };
  };

  # child pipeline templatePath wins over allPipelines
  test-gitlab-ci-pipeline-call-child-pipeline-template-path-overrides-all-pipelines = {
    expr = test-lib.eval-gitlab-ci [
      {
        _module.args.allPipelines = {
          infra.gitlab-ci.templatePath = "gitlab-templates/infra/template.yml";
        };
      }
      {
        pipelines.infra = {
          gitlab-ci.asComponent = true;
          gitlab-ci.templatePath = "ci/child/infra.yml";
          jobs.apply.commands = [ "tofu apply" ];
        };
        jobs.deploy.pipelineCall.pipeline = "infra";
      }
    ];
    expected = {
      include = [ { local = "ci/child/infra.yml"; } ];
    };
  };
}
