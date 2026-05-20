{ test-lib, ... }:

let
  terraformJobs =
    { name, ... }:
    {
      jobs = {
        "${name}:validate" = { };
        "${name}:plan" = { };
        "${name}:deploy" = { };
      };
    };

  terraformEnvJobs =
    { name, env, ... }:
    {
      jobs = {
        "${name}:validate" = { };
        "${name}:${env}:plan" = { };
        "${name}:${env}:deploy" = { };
      };
    };

  terraformStackJobs =
    { name, ... }:
    {
      jobs = {
        "${name}:validate" = { };
        "${name}:plan" = { };
        "${name}:deploy" = { };
      };
      jobSets."${name}" = {
        jobs = [
          "${name}:validate"
          "${name}:plan"
          "${name}:deploy"
        ];
      };
    };
in
{
  test-gitlab-ci-job-factories = {
    expr = test-lib.eval-gitlab-ci {
      jobFactories = {
        terraformJobs = {
          fn = terraformJobs;
          applications = [ { name = "tf-job"; } ];
        };
        terraformEnvJobs = {
          fn = terraformEnvJobs;
          applications = [ { name = "tf-env-job"; env = "dev"; } ];
        };
      };
    };

    expected = {
      "tf-job:validate" = { };
      "tf-job:plan" = { };
      "tf-job:deploy" = { };

      "tf-env-job:validate" = { };
      "tf-env-job:dev:plan" = { };
      "tf-env-job:dev:deploy" = { };
    };
  };

  test-gitlab-ci-job-factory-sets-jobs = {
    expr = test-lib.eval-gitlab-ci {
      jobFactories.terraformStackJobs = {
        fn = terraformStackJobs;
        applications = [ { name = "my-stack"; } ];
      };
    };

    expected = {
      "my-stack:validate" = { };
      "my-stack:plan" = { };
      "my-stack:deploy" = { };
    };
  };

  test-gitlab-ci-job-factory-sets-jobsets = {
    expr =
      let
        cfg = test-lib.evalConfig {
          jobFactories.terraformStackJobs = {
            fn = terraformStackJobs;
            applications = [ { name = "my-stack"; } ];
          };
        };
      in
      cfg.jobSets;

    expected = {
      "my-stack" = {
        jobs = [
          "my-stack:validate"
          "my-stack:plan"
          "my-stack:deploy"
        ];
        jobDefaults = { };
        needs = [ ];
        tags = [ ];
      };
    };
  };
}
