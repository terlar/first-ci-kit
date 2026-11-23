{ ci-lib, ... }:

let
  inherit (ci-lib.stepBlocks) instantiate usedBlocks;

  # Plain attrsets shaped like the evaluated stepType/stepBlockType (all
  # fields present with their defaults), used consistently across this file.
  step =
    {
      run ? null,
      block ? null,
      inputs ? { },
      name ? null,
      env ? { },
      github-actions ? null,
      gitlab-ci ? null,
    }:
    {
      inherit
        run
        block
        inputs
        name
        env
        github-actions
        gitlab-ci
        ;
    };

  greetBlock = {
    description = "";
    inputs.who = {
      description = "";
      default = "world";
    };
    steps = { inputs }: [ (step { run = "echo ${inputs.who}"; }) ];
  };

  outerBlock = {
    description = "";
    inputs = { };
    steps = _: [ (step { block = "greet"; }) ];
  };

  blocks = {
    greet = greetBlock;
    outer = outerBlock;
  };
in
{
  test-lib-step-blocks-instantiate-run = {
    expr = instantiate { blocks = { }; } (step {
      run = "x";
    });
    expected = [ (step { run = "x"; }) ];
  };

  test-lib-step-blocks-instantiate-defaults = {
    expr = instantiate { inherit blocks; } (step {
      block = "greet";
    });
    expected = [ (step { run = "echo world"; }) ];
  };

  test-lib-step-blocks-instantiate-input-override = {
    expr = instantiate { inherit blocks; } (step {
      block = "greet";
      inputs.who = "\${{ needs.a.result }}";
    });
    expected = [ (step { run = "echo \${{ needs.a.result }}"; }) ];
  };

  test-lib-step-blocks-nested = {
    expr = instantiate { inherit blocks; } (step {
      block = "outer";
    });
    expected = [ (step { run = "echo world"; }) ];
  };

  test-lib-step-blocks-used-transitive = {
    expr = usedBlocks { inherit blocks; } [ (step { block = "outer"; }) ];
    expected = [
      "greet"
      "outer"
    ];
  };

  test-lib-step-blocks-unknown-block-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (instantiate { blocks = { }; } (step {
          block = "nope";
        })) null
      )).success;
    expected = false;
  };

  test-lib-step-blocks-unknown-input-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (instantiate { inherit blocks; } (step {
          block = "greet";
          inputs.nope = "x";
        })) null
      )).success;
    expected = false;
  };

  test-lib-step-blocks-missing-required-input-fails = {
    expr =
      let
        requiresBlock = {
          description = "";
          inputs.needed = {
            description = "";
            default = null;
          };
          steps = { inputs }: [ (step { run = inputs.needed; }) ];
        };
      in
      (builtins.tryEval (
        builtins.deepSeq (instantiate
          {
            blocks = {
              requires = requiresBlock;
            };
          }
          (step {
            block = "requires";
          })
        ) null
      )).success;
    expected = false;
  };

  test-lib-step-blocks-cycle-fails = {
    expr =
      let
        cyclic = {
          a = {
            description = "";
            inputs = { };
            steps = _: [ (step { block = "b"; }) ];
          };
          b = {
            description = "";
            inputs = { };
            steps = _: [ (step { block = "a"; }) ];
          };
        };
      in
      (builtins.tryEval (
        builtins.deepSeq (instantiate { blocks = cyclic; } (step {
          block = "a";
        })) null
      )).success;
    expected = false;
  };

  test-lib-step-blocks-both-run-and-block-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (instantiate { blocks = { }; } (step {
          run = "x";
          block = "greet";
        })) null
      )).success;
    expected = false;
  };

  test-lib-step-blocks-nothing-set-fails = {
    expr =
      (builtins.tryEval (builtins.deepSeq (instantiate { blocks = { }; } (step { })) null)).success;
    expected = false;
  };

  test-lib-step-blocks-inputs-without-block-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (instantiate { blocks = { }; } (step {
          run = "x";
          inputs.foo = "bar";
        })) null
      )).success;
    expected = false;
  };
}
