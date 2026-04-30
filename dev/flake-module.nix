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

      checks.gha-path-changes = pkgs.callPackage ./checks/gha-path-changes.nix { inherit lib config; };
      checks.gha-job-summary = pkgs.callPackage ./checks/gha-job-summary.nix { inherit lib config; };

      checks.git-hooks = pkgs.callPackage ./checks/git-hooks.nix { inherit lib config; };

      packages.module-docs = pkgs.callPackage ../packages/module-docs {
        moduleRoot = ../module;
      };
    };
}
