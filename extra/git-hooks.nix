{
  config,
  lib,
  flake-parts-lib,
  ...
}:

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
      # Build a shell script that evaluates all pipelines in one nix build call
      # by referencing the bundle derivation, then copies each file to its destination.
      writePipelineGenerator =
        { backend, pipelines }:
        pkgs.writeShellApplication {
          name = "generate-${backend}";
          runtimeInputs = [ pkgs.yq-go ];
          text =
            let
              copyPipeline = name: outputPath: ''
                mkdir -p "$(dirname "${outputPath}")"
                yq --prettyPrint --output-format yaml "$bundle/${name}.yml" > "${outputPath}"
              '';
            in
            ''
              bundle="$(nix build --extra-experimental-features 'nix-command flakes' \
                --print-out-paths \
                .#ci-pipelines-${backend}
              )"
            ''
            + lib.concatStringsSep "\n" (lib.mapAttrsToList copyPipeline pipelines);
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
                  default = ".github/workflows/ci.yml";
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
  options = {
    first-ci-kit.autoConfigureHooks = lib.mkOption {
      type = types.bool;
      default = true;
      description = ''
        When enabled, automatically populate `settings.pipelines` on the
        `first-ci-kit-gen-github-actions` and `first-ci-kit-gen-gitlab-ci`
        pre-commit hooks from `first-ci-kit.pipelines`, following the
        name-based path convention.  Set to `false` to manage hook pipeline
        mappings manually.
      '';
    };

    perSystem = flake-parts-lib.mkPerSystemOption {
      options.pre-commit.settings = lib.mkOption {
        type = types.submoduleWith { modules = [ extendHooks ]; };
      };
    };
  };

  config = lib.mkIf config.first-ci-kit.autoConfigureHooks {
    # Auto-populate settings.pipelines for the pre-commit hooks from pipeline
    # definitions.  The default pipeline uses well-known root output paths;
    # all other pipelines follow the name-based convention so they require no
    # manual hook configuration.
    perSystem.pre-commit.settings.hooks = {
      first-ci-kit-gen-github-actions.settings.pipelines = lib.mkDefault (
        lib.mapAttrs (
          name: _: ".github/workflows/${if name == "default" then "ci" else name}.yml"
        ) config.first-ci-kit.pipelines
      );
      first-ci-kit-gen-gitlab-ci.settings.pipelines = lib.mkDefault (
        lib.mapAttrs (
          name: pipeline: if name == "default" then ".gitlab-ci.yml" else pipeline.gitlab-ci.templatePath
        ) config.first-ci-kit.pipelines
      );
    };
  };
}
