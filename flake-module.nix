{
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (lib) mkOption types;
in
{
  options = {
    first-ci-kit.pipelines = mkOption {
      type = types.lazyAttrsOf (types.submoduleWith { modules = [ ./module ]; });
      default = { };
      description = "Pipelines for CI.";
    };

    perSystem = flake-parts-lib.mkPerSystemOption (
      {
        config,
        options,
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
        options.pre-commit.settings = mkOption {
          type = types.submoduleWith {
            modules = [
              (
                { hookModule, ... }:
                {
                  options.hooks = {
                    first-ci-kit-gen-github-actions = mkOption {
                      description = "generate GitHub Actions workflow";
                      type = types.submodule {
                        imports = [ hookModule ];
                        options.settings = {
                          pipeline = mkOption {
                            type = types.str;
                            description = "The pipeline to generate.";
                            default = "default";
                            example = "pr";
                          };

                          outputPath = mkOption {
                            type = types.str;
                            description = "The path of the output file generated.";
                            default = ".github/workflows/ci.yaml";
                            example = ".github/workflows/example.yaml";
                          };
                        };
                      };
                    };

                    first-ci-kit-gen-gitlab-ci = mkOption {
                      description = "generate GitLab CI pipeline";
                      type = types.submodule {
                        imports = [ hookModule ];
                        options.settings = {
                          pipeline = mkOption {
                            type = types.str;
                            description = "The pipeline to generate.";
                            default = "default";
                            example = "pr";
                          };

                          outputPath = mkOption {
                            type = types.str;
                            description = "The path of the output file generated.";
                            default = ".gitlab-ci.yml";
                            example = ".gitlab/ci.yml";
                          };
                        };
                      };
                    };
                  };
                }
              )
            ];
          };
        };

        config.pre-commit = lib.mkIf (options ? pre-commit) {
          settings.hooks = {
            first-ci-kit-gen-github-actions = {
              name = "generate-github-actions";
              description = "generate GitHub Actions workflow";
              package = writePipelineGenerator {
                name = "github-actions";
                hook = config.pre-commit.settings.hooks.first-ci-kit-gen-github-actions;
              };
              entry = "${config.pre-commit.settings.hooks.first-ci-kit-gen-github-actions.package}/bin/generate-github-actions";
              files = lib.mkDefault "\\.nix$";
              pass_filenames = false;
            };

            first-ci-kit-gen-gitlab-ci = {
              name = "generate-gitlab-ci";
              description = "generate GitLab CI pipeline";
              package = writePipelineGenerator {
                name = "gitlab-ci";
                hook = config.pre-commit.settings.hooks.first-ci-kit-gen-gitlab-ci;
              };
              entry = "${config.pre-commit.settings.hooks.first-ci-kit-gen-gitlab-ci.package}/bin/generate-gitlab-ci";
              files = lib.mkDefault "\\.nix$";
              pass_filenames = false;
            };
          };
        };
      }
    );
  };

  config.perSystem = {
    process-compose = lib.mapAttrs' (name: value: {
      name = "pipeline-${name}";
      value = value.pipeline.process-compose;
    }) config.first-ci-kit.pipelines;

    legacyPackages = lib.mkMerge [
      (lib.mapAttrs' (name: value: {
        name = "ci-pipeline-github-actions-${name}";
        value = value.pipeline.github-actions.file;
      }) config.first-ci-kit.pipelines)

      (lib.mapAttrs' (name: value: {
        name = "ci-pipeline-gitlab-ci-${name}";
        value = value.pipeline.gitlab-ci.file;
      }) config.first-ci-kit.pipelines)
    ];
  };
}
