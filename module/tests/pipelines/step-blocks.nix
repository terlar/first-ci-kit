{ lib, test-lib, ... }:

{
  test-pipelines-step-blocks-child-inherits = {
    expr =
      lib.pipe
        {
          stepBlocks.greet = {
            steps = _: [ { run = "echo hi"; } ];
          };
          pipelines.child = { };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.pipelines.child.stepBlocks ? greet)
        ];
    expected = true;
  };
}
