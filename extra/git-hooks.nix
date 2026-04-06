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
        { backend, pipelines }:
        pkgs.writeShellApplication {
          name = "generate-${backend}";
          runtimeInputs = [ pkgs.yq-go ];
          text =
            let
              generatePipeline = name: outputPath: ''
                out="$(nix build --extra-experimental-features 'nix-command flakes' \
                  --print-out-paths \
                  .#ci-pipeline-${backend}-${name}
                )"

                mkdir -p "$(dirname "${outputPath}")"
                yq --prettyPrint --output-format yaml "$out" > "${outputPath}"
              '';
            in
            lib.concatStringsSep "\n" (lib.mapAttrsToList generatePipeline pipelines);
        };
    in
    {
      options.hooks = {
        first-ci-kit-gen-github-actions = lib.mkOption {
          description = "generate GitHub Actions workflow";
          type = types.submodule {
            imports = [ hookModule ];
            options.settings = {
              pipelines = lib.mkOption {
                type = types.attrsOf types.str;
                default = {
                  default = ".github/workflows/ci.yaml";
                };
                description = "Pipeline name to output path mapping.";
                example = lib.literalExpression ''
                  {
                    default = ".github/workflows/ci.yaml";
                    nightly = ".github/workflows/nightly.yaml";
                  }
                '';
              };
            };
          };
        };

        first-ci-kit-gen-gitlab-ci = lib.mkOption {
          description = "generate GitLab CI pipeline";
          type = types.submodule {
            imports = [ hookModule ];
            options.settings = {
              pipelines = lib.mkOption {
                type = types.attrsOf types.str;
                default = {
                  default = ".gitlab-ci.yml";
                };
                description = "Pipeline name to output path mapping.";
                example = lib.literalExpression ''
                  {
                    default = ".gitlab-ci.yml";
                    pr = ".gitlab/ci-pr.yml";
                  }
                '';
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
            backend = "github-actions";
            inherit (config.hooks.first-ci-kit-gen-github-actions.settings) pipelines;
          };
          entry = "${config.hooks.first-ci-kit-gen-github-actions.package}/bin/generate-github-actions";
          files = lib.mkDefault "\\.nix$";
          pass_filenames = false;
        };

        first-ci-kit-gen-gitlab-ci = {
          name = "generate-gitlab-ci";
          description = "generate GitLab CI pipeline";
          package = writePipelineGenerator {
            backend = "gitlab-ci";
            inherit (config.hooks.first-ci-kit-gen-gitlab-ci.settings) pipelines;
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
