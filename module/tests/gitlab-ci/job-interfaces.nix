{ lib, test-lib, ... }:

{
  test-gitlab-ci-job-interface = {
    expr = test-lib.eval-gitlab-ci (
      { config, ... }:
      {
        jobInterfaces = {
          terraformJobs =
            { name, ... }:
            {
              "${name}:validate" = { };
              "${name}:plan" = { };
              "${name}:deploy" = { };
            };
          terraformEnvJobs =
            { name, env, ... }:
            {
              "${name}:validate" = { };
              "${name}:${env}:plan" = { };
              "${name}:${env}:deploy" = { };
            };
        };

        jobs = lib.mkMerge [
          (config.jobInterfaces.terraformJobs { name = "tf-job"; })
          (config.jobInterfaces.terraformEnvJobs {
            name = "tf-env-job";
            env = "dev";
          })
        ];
      }
    );

    expected = {
      "tf-job:validate" = { };
      "tf-job:plan" = { };
      "tf-job:deploy" = { };

      "tf-env-job:validate" = { };
      "tf-env-job:dev:plan" = { };
      "tf-env-job:dev:deploy" = { };
    };
  };
}
