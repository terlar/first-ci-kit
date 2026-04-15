{ test-lib, ... }:

{
  test-pipeline-input-minimal = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            inputs.service = { };
          };
        };
      in
      cfg.pipelines.child.inputs.service;
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
      let
        cfg = test-lib.evalConfig {
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
        };
      in
      cfg.pipelines.child.inputs.env;
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
      let
        cfg = test-lib.evalConfig {
          pipelines.child = {
            outputs.plan = {
              value = "\${{ jobs.plan.outputs.plan }}";
            };
          };
        };
      in
      cfg.pipelines.child.outputs.plan;
    expected = {
      value = "\${{ jobs.plan.outputs.plan }}";
      description = "";
    };
  };
}
