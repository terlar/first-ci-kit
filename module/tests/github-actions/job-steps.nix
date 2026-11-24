{ test-lib, ... }:

let
  greetBlock = {
    inputs.who.default = "world";
    steps = { inputs }: [ { run = "echo ${inputs.who}"; } ];
  };
in
{
  test-github-actions-steps-run = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.build = {
        steps = [
          {
            run = "a";
            name = "A";
            env.X = "1";
          }
        ];
        commands = [ "b" ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            name = "A";
            run = "a";
            env.X = "1";
          }
          { run = "b"; }
        ];
      };
    };
  };

  test-github-actions-steps-raw-only = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.build = {
        steps = [
          { github-actions.uses = "x/y@v1"; }
          { gitlab-ci = [ "z" ]; }
        ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          { uses = "x/y@v1"; }
        ];
      };
    };
  };

  test-github-actions-steps-expanded-block = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      stepBlocks.greet = greetBlock;
      jobs.build = {
        steps = [
          {
            block = "greet";
            inputs.who = "a";
          }
          {
            block = "greet";
            inputs.who = "b";
          }
        ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "echo a"; }
          { run = "echo b"; }
        ];
      };
    };
  };

  test-github-actions-steps-expanded-default = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      stepBlocks.greet = greetBlock;
      jobs.build = {
        steps = [ { block = "greet"; } ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "echo world"; }
        ];
      };
    };
  };

  test-github-actions-steps-native-caller = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        stepBlocks.mode = "native";
      };
      stepBlocks.greet = greetBlock;
      jobs.build = {
        steps = [
          {
            block = "greet";
            inputs.who = "\${{ needs.a.result }}";
          }
        ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            uses = "./.github/actions/greet";
            "with".who = "\${{ needs.a.result }}";
          }
        ];
      };
    };
  };

  test-github-actions-steps-native-no-with = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        stepBlocks.mode = "native";
      };
      stepBlocks.greet = greetBlock;
      jobs.build = {
        steps = [ { block = "greet"; } ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          { uses = "./.github/actions/greet"; }
        ];
      };
    };
  };

  test-github-actions-steps-native-checkout-ref = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        stepBlocks.mode = "native";
      };
      stepBlocks.greet = greetBlock;
      jobs.build = {
        checkout.ref = "x";
        steps = [ { block = "greet"; } ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          {
            uses = "actions/checkout@v7";
            "with".ref = "x";
          }
          { uses = "./.github/actions/greet"; }
        ];
      };
    };
  };

  test-github-actions-steps-native-no-checkout-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-github-actions {
          github-actions = {
            defaultRunsOn = "ubuntu-latest";
            stepBlocks.mode = "native";
          };
          stepBlocks.greet = greetBlock;
          jobs.build = {
            checkout = false;
            steps = [ { block = "greet"; } ];
          };
        }) null
      )).success;
    expected = false;
  };

  test-github-actions-steps-native-missing-required-input-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-github-actions {
          github-actions = {
            defaultRunsOn = "ubuntu-latest";
            stepBlocks.mode = "native";
          };
          stepBlocks.requires = {
            inputs.needed.default = null;
            steps = { inputs }: [ { run = inputs.needed; } ];
          };
          jobs.build = {
            steps = [ { block = "requires"; } ];
          };
        }) null
      )).success;
    expected = false;
  };

  # Expanded mode must also reject a missing required input, even when the
  # block's steps never read it.
  test-github-actions-steps-expanded-unused-missing-required-input-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-github-actions {
          github-actions.defaultRunsOn = "ubuntu-latest";
          stepBlocks.requires = {
            inputs.needed.default = null;
            steps = _: [ { run = "echo hi"; } ];
          };
          jobs.build = {
            steps = [ { block = "requires"; } ];
          };
        }) null
      )).success;
    expected = false;
  };

  test-github-actions-steps-expanded-override-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-github-actions {
          github-actions.defaultRunsOn = "ubuntu-latest";
          stepBlocks.greet = greetBlock;
          jobs.build = {
            steps = [
              {
                block = "greet";
                github-actions."if" = "always()";
              }
            ];
          };
        }) null
      )).success;
    expected = false;
  };

  test-github-actions-steps-expanded-nested-override-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-github-actions {
          github-actions.defaultRunsOn = "ubuntu-latest";
          stepBlocks = {
            greet = greetBlock;
            outer.steps = _: [
              {
                block = "greet";
                github-actions."if" = "always()";
              }
            ];
          };
          jobs.build = {
            steps = [ { block = "outer"; } ];
          };
        }) null
      )).success;
    expected = false;
  };

  # Expanded: a block step's env flows onto every leaf (leaf env wins) and
  # its name prefixes theirs, at every nesting level.
  test-github-actions-steps-expanded-nested-env = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      stepBlocks = {
        greet = greetBlock;
        outer.steps = _: [
          {
            block = "greet";
            name = "Inner";
            env.Z = "2";
          }
          {
            run = "b";
            name = "B";
            env.X = "leaf";
          }
          { github-actions.uses = "x/y@v1"; }
        ];
      };
      jobs.build.steps = [
        {
          block = "outer";
          name = "Outer";
          env = {
            X = "block";
            Y = "1";
          };
        }
      ];
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            name = "Outer: Inner";
            run = "echo world";
            env = {
              X = "block";
              Y = "1";
              Z = "2";
            };
          }
          {
            name = "Outer: B";
            run = "b";
            env = {
              X = "leaf";
              Y = "1";
            };
          }
          {
            name = "Outer";
            uses = "x/y@v1";
            env = {
              X = "block";
              Y = "1";
            };
          }
        ];
      };
    };
  };

  test-github-actions-steps-native-caller-name-env-override = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        stepBlocks.mode = "native";
      };
      stepBlocks.greet = greetBlock;
      jobs.build.steps = [
        {
          block = "greet";
          name = "Greet";
          env.X = "1";
          github-actions."if" = "always()";
        }
      ];
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            uses = "./.github/actions/greet";
            name = "Greet";
            env.X = "1";
            "if" = "always()";
          }
        ];
      };
    };
  };

  test-github-actions-steps-native-unknown-input-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-github-actions {
          github-actions = {
            defaultRunsOn = "ubuntu-latest";
            stepBlocks.mode = "native";
          };
          stepBlocks.greet = greetBlock;
          jobs.build.steps = [
            {
              block = "greet";
              inputs.nope = "x";
            }
          ];
        }) null
      )).success;
    expected = false;
  };

  test-github-actions-steps-native-cycle-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq
          (test-lib.evalConfig {
            github-actions.stepBlocks.mode = "native";
            stepBlocks = {
              a.steps = _: [ { block = "b"; } ];
              b.steps = _: [ { block = "a"; } ];
            };
            jobs.build.steps = [ { block = "a"; } ];
          }).github-actions.actions
          null
      )).success;
    expected = false;
  };

  test-github-actions-steps-ordering = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.build = {
        artifacts.download.name = "down";
        artifacts.upload = {
          name = "up";
          paths = [ "out/" ];
        };
        steps = [ { run = "s"; } ];
        commands = [ "c" ];
      };
    };
    expected = {
      jobs.build = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            uses = "actions/download-artifact@v8";
            "with".name = "down";
          }
          { run = "s"; }
          { run = "c"; }
          {
            uses = "actions/upload-artifact@v7";
            "with" = {
              name = "up";
              path = "out/";
            };
          }
        ];
      };
    };
  };
}
