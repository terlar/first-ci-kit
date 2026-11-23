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

  test-pipelines-step-blocks-top-level = {
    expr =
      lib.pipe
        {
          modules = [
            ../../top-level
            {
              stepBlocks.greet.steps = _: [ { run = "echo world"; } ];
              pipelines.p.jobs.j.steps = [ { block = "greet"; } ];
            }
          ];
        }
        [
          lib.evalModules
          (eval: eval.config)
          (
            cfg:
            lib.concatMap (
              s: lib.optional (s.run or null == "echo world") true
            ) cfg.pipelines.p.github-actions.settings.jobs.j.steps
          )
          (matches: matches != [ ])
        ];
    expected = true;
  };
}
