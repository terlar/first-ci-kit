{
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.dev-flake.flakeModule
    inputs.process-compose.flakeModule
    ../extra/process-compose.nix
  ];

  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  dev.name = "terlar/first-ci-kit";

  # Dogfood
  first-ci-kit.pipelines = {
    default = {
      pipeline = {
        github-actions = {
          defaultRunsOn = "ubuntu-latest";
          settings = {
            name = "CI";
            on.push = {
              branches = [ "main" ];
            };
            on.pull_request = {
              branches = [ "main" ];
            };
          };
        };

        process-compose.cli.environment.PC_DISABLE_TUI = true;
      };

      jobs = {
        check = {
          github-actions = {
            steps = [
              {
                uses = "cachix/install-nix-action@v31";
                "with" = {
                  extra_nix_config = ''
                    max-jobs = auto
                  '';
                };
              }
              {
                uses = "cachix/cachix-action@v17";
                "with" = {
                  useDaemon = true;
                  name = "terlar";
                  extraPullNames = "cuda-maintainers";
                  authToken = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
                };
              }
            ];
          };

          commands = [
            "nix eval .#tests.first-ci-kit"
            "nix flake check"
          ];
        };
      };
    };
  };

  flake.tests.first-ci-kit = import ../module/tests {
    inherit lib;
    ci-lib = import ../module/lib { inherit lib; };
  };

  perSystem =
    { config, pkgs, ... }:
    {
      pre-commit.check.enable = false;
      pre-commit.settings.hooks = {
        conform.enable = true;
        generate-module-docs = {
          enable = true;
          stages = [ "pre-push" ];

          name = "generate-module-docs";
          description = "Generate first-ci-kit module documentation.";
          entry =
            lib.pipe
              {
                name = "generate-module-docs";
                text = ''
                  out="$(nix build --extra-experimental-features 'nix-command flakes' \
                    --print-out-paths \
                    .#module-docs
                  )"

                  cp --no-preserve=all --force "$out" "module/README.md"
                '';
              }
              [
                pkgs.writeShellApplication
                lib.getExe
              ];

          files = "^module/.*\\.nix$";
        };

        first-ci-kit-gen-github-actions = {
          enable = true;
          files = "^dev/flake-module.nix$";
        };
      };

      checks.git-hooks =
        let
          inherit (config.pre-commit.settings) hooks;
          gh = hooks.first-ci-kit-gen-github-actions;
          gl = hooks.first-ci-kit-gen-gitlab-ci;

          tests = {
            "github-actions: default pipelines" = {
              check = gh.settings.pipelines.default == ".github/workflows/ci.yaml";
            };

            "gitlab-ci: default pipelines" = {
              check = gl.settings.pipelines.default == ".gitlab-ci.yml";
            };

            "github-actions: hook name" = {
              check = gh.name == "generate-github-actions";
            };

            "gitlab-ci: hook name" = {
              check = gl.name == "generate-gitlab-ci";
            };

            "github-actions: pass_filenames is false" = {
              check = !gh.pass_filenames;
            };

            "gitlab-ci: pass_filenames is false" = {
              check = !gl.pass_filenames;
            };
          };
        in
        pkgs.runCommand "test-git-hooks" { } (
          ''
            set -e
          ''
          + lib.concatStrings (
            lib.mapAttrsToList (
              name:
              { check }:
              if check then
                ""
              else
                ''
                  echo "FAILED: ${name}"
                  exit 1
                ''
            ) tests
          )
          + ''
            echo "All git-hooks tests passed" > $out
          ''
        );

      packages.module-docs = pkgs.callPackage ../packages/module-docs {
        moduleRoot = ../module;
      };
    };
}
