{ lib, test-lib, ... }:

{
  test-pipeline-input-minimal = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            inputs.service = { };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.inputs.service)
        ];
    expected = {
      type = "string";
      required = false;
      default = null;
      description = "";
      options = [ ];
    };
  };

  test-pipeline-input-full = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            inputs.env = {
              type = "choice";
              required = true;
              default = "dev";
              description = "Target environment";
              options = [
                "dev"
                "acc"
                "prd"
              ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.inputs.env)
        ];
    expected = {
      type = "choice";
      required = true;
      default = "dev";
      description = "Target environment";
      options = [
        "dev"
        "acc"
        "prd"
      ];
    };
  };

  test-pipeline-output-minimal = {
    expr =
      lib.pipe
        {
          pipelines.child = {
            outputs.plan = {
              value = "\${{ jobs.plan.outputs.plan }}";
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.outputs.plan)
        ];
    expected = {
      value = "\${{ jobs.plan.outputs.plan }}";
      description = "";
    };
  };
}
