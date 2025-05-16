{
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (lib) types;
  inherit (config.first-ci-kit) pipelines;
in
{
  options = {
    first-ci-kit.pipelines = lib.mkOption {
      type = types.lazyAttrsOf (types.submoduleWith { modules = [ ./module ]; });
      default = { };
      description = "Pipelines for CI.";
    };

    perSystem = flake-parts-lib.mkPerSystemOption {
      options.pre-commit.settings = lib.mkOption {
        type = types.submoduleWith { modules = [ ./hooks.nix ]; };
      };
    };
  };

  config.perSystem =
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
    lib.mkMerge [
      {
        legacyPackages = lib.mkMerge [
          (lib.mapAttrs' (name: value: {
            name = "ci-pipeline-github-actions-${name}";
            value = value.pipeline.github-actions.file;
          }) pipelines)

          (lib.mapAttrs' (name: value: {
            name = "ci-pipeline-gitlab-ci-${name}";
            value = value.pipeline.gitlab-ci.file;
          }) pipelines)
        ];
      }

      (lib.optionalAttrs (options ? process-compose) {
        process-compose = lib.mapAttrs' (name: value: {
          name = "pipeline-${name}";
          value = value.pipeline.process-compose;
        }) pipelines;
      })

      {
        pre-commit.settings.hooks = {
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
      }
    ];
}
