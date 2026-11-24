{ test-lib, ... }:

let
  greetBlock = {
    inputs.who.default = "world";
    steps = { inputs }: [ { run = "echo ${inputs.who}"; } ];
  };
in
{
  test-gitlab-ci-steps-run-and-commands = {
    expr = test-lib.eval-gitlab-ci {
      jobs.build = {
        steps = [ { run = "a"; } ];
        commands = [ "b" ];
      };
    };
    expected = {
      build.script = [
        "a"
        "b"
      ];
    };
  };

  test-gitlab-ci-steps-env = {
    expr = test-lib.eval-gitlab-ci {
      jobs.build = {
        steps = [
          {
            run = "echo $X";
            env.X = "say \"hi\" $CI_COMMIT_SHA";
          }
        ];
      };
    };
    expected = {
      build.script = [
        "( export X=\"say \\\"hi\\\" $CI_COMMIT_SHA\"\necho $X\n)"
      ];
    };
  };

  test-gitlab-ci-steps-name = {
    expr = test-lib.eval-gitlab-ci {
      jobs.build = {
        steps = [
          {
            run = "a";
            name = "Build";
          }
        ];
      };
    };
    expected = {
      build.script = [
        "echo -e \"\\e[0Ksection_start:$(date +%s):step_0[collapsed=true]\\r\\e[0KBuild\""
        "a"
        "echo -e \"\\e[0Ksection_end:$(date +%s):step_0\\r\\e[0K\""
      ];
    };
  };

  test-gitlab-ci-steps-block = {
    expr = test-lib.eval-gitlab-ci {
      stepBlocks.greet = greetBlock;
      jobs.build = {
        steps = [
          {
            block = "greet";
            inputs.who = "$CI_JOB_NAME";
          }
        ];
      };
    };
    expected = {
      build.script = [ "echo $CI_JOB_NAME" ];
    };
  };

  test-gitlab-ci-steps-raw = {
    expr = test-lib.eval-gitlab-ci {
      jobs.build = {
        steps = [
          {
            gitlab-ci = [
              "x"
              "y"
            ];
          }
          {
            github-actions.uses = "a/b@v1";
            name = "GitHub only";
          }
        ];
      };
    };
    expected = {
      build.script = [
        "x"
        "y"
      ];
    };
  };

  test-gitlab-ci-steps-native-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-gitlab-ci {
          gitlab-ci.stepBlocks.mode = "native";
          jobs.build = {
            steps = [ { run = "a"; } ];
          };
        }) null
      )).success;
    expected = false;
  };

  test-gitlab-ci-steps-missing-required-input-fails = {
    expr =
      (builtins.tryEval (
        builtins.deepSeq (test-lib.eval-gitlab-ci {
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

  # Section ids follow each step's path through nested blocks.
  test-gitlab-ci-steps-nested-block-section-ids = {
    expr = test-lib.eval-gitlab-ci {
      stepBlocks.inner.steps = _: [
        {
          run = "a";
          name = "A";
        }
      ];
      stepBlocks.outer.steps = _: [
        { run = "x"; }
        {
          block = "inner";
          name = "Inner";
        }
      ];
      jobs.build.steps = [ { block = "outer"; } ];
    };
    expected = {
      build.script = [
        "x"
        "echo -e \"\\e[0Ksection_start:$(date +%s):step_0_1[collapsed=true]\\r\\e[0KInner\""
        "echo -e \"\\e[0Ksection_start:$(date +%s):step_0_1_0[collapsed=true]\\r\\e[0KA\""
        "a"
        "echo -e \"\\e[0Ksection_end:$(date +%s):step_0_1_0\\r\\e[0K\""
        "echo -e \"\\e[0Ksection_end:$(date +%s):step_0_1\\r\\e[0K\""
      ];
    };
  };

  test-gitlab-ci-steps-byte-identical = {
    expr = test-lib.eval-gitlab-ci {
      jobs.build = {
        commands = [ "echo hello" ];
      };
    };
    expected = {
      build.script = [ "echo hello" ];
    };
  };
}
