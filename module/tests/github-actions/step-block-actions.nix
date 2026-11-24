{ test-lib, ... }:

let
  greetBlock = {
    description = "Say hi";
    inputs.who.default = "world";
    steps = { inputs }: [ { run = "echo ${inputs.who}"; } ];
  };

  outerBlock = {
    steps = _: [ { block = "greet"; } ];
  };
in
{
  test-github-actions-step-block-actions-expanded-empty = {
    expr =
      (test-lib.evalConfig {
        stepBlocks.greet = greetBlock;
        jobs.build.steps = [ { block = "greet"; } ];
      }).github-actions.actions;
    expected = { };
  };

  test-github-actions-step-block-actions-native = {
    expr =
      (test-lib.evalConfig {
        github-actions.stepBlocks.mode = "native";
        stepBlocks.greet = greetBlock;
        jobs.build.steps = [ { block = "greet"; } ];
      }).github-actions.actions;
    expected = {
      greet = {
        name = "greet";
        description = "Say hi";
        inputs.who = {
          required = false;
          default = "world";
        };
        runs = {
          using = "composite";
          steps = [
            {
              run = "echo \${{ inputs.who }}";
              shell = "bash";
            }
          ];
        };
      };
    };
  };

  test-github-actions-step-block-actions-nested = {
    expr =
      let
        actions =
          (test-lib.evalConfig {
            github-actions.stepBlocks.mode = "native";
            stepBlocks = {
              greet = greetBlock;
              outer = outerBlock;
            };
            jobs.build.steps = [ { block = "outer"; } ];
          }).github-actions.actions;
      in
      {
        hasGreet = actions ? greet;
        hasOuter = actions ? outer;
        inherit (actions) outer;
      };
    expected = {
      hasGreet = true;
      hasOuter = true;
      outer = {
        name = "outer";
        inputs = { };
        runs = {
          using = "composite";
          steps = [
            { uses = "./.github/actions/greet"; }
          ];
        };
      };
    };
  };

  test-github-actions-step-block-actions-unused = {
    expr =
      (test-lib.evalConfig {
        github-actions.stepBlocks.mode = "native";
        stepBlocks = {
          greet = greetBlock;
          unused.steps = _: [ { run = "echo unused"; } ];
        };
        jobs.build.steps = [ { block = "greet"; } ];
      }).github-actions.actions
        ? unused;
    expected = false;
  };

  test-github-actions-step-block-actions-disabled-job = {
    expr =
      (test-lib.evalConfig {
        github-actions.stepBlocks.mode = "native";
        stepBlocks.greet = greetBlock;
        jobs.build = {
          enable = false;
          steps = [ { block = "greet"; } ];
        };
      }).github-actions.actions
        ? greet;
    expected = false;
  };

  test-github-actions-step-block-actions-explicit-shell = {
    expr =
      (test-lib.evalConfig {
        github-actions.stepBlocks.mode = "native";
        stepBlocks.pwsh.steps = _: [
          {
            run = "Write-Host hi";
            github-actions.shell = "pwsh";
          }
        ];
        jobs.build.steps = [ { block = "pwsh"; } ];
      }).github-actions.actions.pwsh.runs.steps;
    expected = [
      {
        run = "Write-Host hi";
        shell = "pwsh";
      }
    ];
  };
}
