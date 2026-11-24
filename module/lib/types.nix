{ lib }:

let
  inherit (lib) types;
in
rec {
  needsType = types.submoduleWith {
    description = "Needs configuration";
    modules = [
      {
        options = {
          job = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job.";
          };

          jobSet = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job set.";
          };

          optional = lib.mkOption {
            type = types.bool;
            default = false;
            description = "Whether need is optional.";
          };

          artifacts = lib.mkOption {
            type = types.bool;
            default = true;
            description = "Whether artifacts from dependency are used.";
          };
        };
      }
    ];
  };

  stepType = types.submodule {
    options = {
      run = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Shell command to run.";
      };

      block = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Name of a stepBlocks entry to use.";
      };

      inputs = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Inputs passed to the block. Only valid together with `block`.";
      };

      name = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional display name for the step.";
      };

      env = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables for this step.";
      };

      github-actions = lib.mkOption {
        type = types.nullOr (types.attrsOf types.anything);
        default = null;
        description = "Raw GitHub Actions step attrs, merged over the rendered step for `run`/`block` (native mode); a GitHub-only step on its own.";
      };

      gitlab-ci = lib.mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "GitLab script lines for a GitLab-only step; ignored when `run` or `block` is set.";
      };
    };
  };

  stepBlockType = types.submodule {
    options = {
      description = lib.mkOption {
        type = types.str;
        default = "";
        description = "Used for the composite action description.";
      };

      inputs = lib.mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              description = lib.mkOption {
                type = types.str;
                default = "";
                description = "Input description.";
              };

              default = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Default value. `null` means the input is required.";
              };
            };
          }
        );
        default = { };
        description = "Declared inputs for this block.";
      };

      steps = lib.mkOption {
        type = types.functionTo (types.listOf stepType);
        description = "Function from `{ inputs }` to a list of steps.";
      };
    };
  };
}
