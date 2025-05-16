{ lib, flake-parts-lib, ... }:

let
  inherit (lib) types;

  extendHooks =
    {
      config,
      hookModule,
      pkgs,
      ...
    }:
    let
      writePipelineGenerator =
        { name, hook }:
        pkgs.writeShellApplication {
          name = "generate-${name}";
          runtimeInputs = [ pkgs.yq-go ];
          text = ''
            out="$(nix build --extra-experimental-features 'nix-command flakes' \
              --print-out-paths \
              .#ci-pipeline-${name}-${hook.settings.pipeline}
            )"

            mkdir -p "$(dirname "${hook.settings.outputPath}")"
            yq --prettyPrint --output-format yaml "$out" > "${hook.settings.outputPath}"
          '';
        };
    in
    {
      options.hooks = {
        first-ci-kit-gen-github-actions = lib.mkOption {
          description = "generate GitHub Actions workflow";
          type = types.submodule {
            imports = [ hookModule ];
            options.settings = {
              pipeline = lib.mkOption {
                type = types.str;
                description = "The pipeline to generate.";
                default = "default";
                example = "pr";
              };

              outputPath = lib.mkOption {
                type = types.str;
                description = "The path of the output file generated.";
                default = ".github/workflows/ci.yaml";
                example = ".github/workflows/example.yaml";
              };
            };
          };
        };

        first-ci-kit-gen-gitlab-ci = lib.mkOption {
          description = "generate GitLab CI pipeline";
          type = types.submodule {
            imports = [ hookModule ];
            options.settings = {
              pipeline = lib.mkOption {
                type = types.str;
                description = "The pipeline to generate.";
                default = "default";
                example = "pr";
              };

              outputPath = lib.mkOption {
                type = types.str;
                description = "The path of the output file generated.";
                default = ".gitlab-ci.yml";
                example = ".gitlab/ci.yml";
              };
            };
          };
        };
      };

      config.hooks = {
        first-ci-kit-gen-github-actions = {
          name = "generate-github-actions";
          description = "generate GitHub Actions workflow";
          package = writePipelineGenerator {
            name = "github-actions";
            hook = config.hooks.first-ci-kit-gen-github-actions;
          };
          entry = "${config.hooks.first-ci-kit-gen-github-actions.package}/bin/generate-github-actions";
          files = lib.mkDefault "\\.nix$";
          pass_filenames = false;
        };

        first-ci-kit-gen-gitlab-ci = {
          name = "generate-gitlab-ci";
          description = "generate GitLab CI pipeline";
          package = writePipelineGenerator {
            name = "gitlab-ci";
            hook = config.hooks.first-ci-kit-gen-gitlab-ci;
          };
          entry = "${config.hooks.first-ci-kit-gen-gitlab-ci.package}/bin/generate-gitlab-ci";
          files = lib.mkDefault "\\.nix$";
          pass_filenames = false;
        };
      };
    };
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.pre-commit.settings = lib.mkOption {
      type = types.submoduleWith { modules = [ extendHooks ]; };
    };
  };
}
