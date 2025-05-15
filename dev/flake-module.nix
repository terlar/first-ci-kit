{ lib, inputs, ... }:

{
  imports = [ inputs.dev-flake.flakeModule ];

  dev.name = "terlar/first-ci-kit";

  # Dogfood
  first-ci-kit.pipelines = {
    default = {
      pipeline.github-actions = {
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

      jobs = {
        check = {
          github-actions = {
            steps = [
              {
                uses = "DeterminateSystems/nix-installer-action@v16";
                "with" = {
                  source-url = "https://install.lix.systems/lix/lix-installer-x86_64-linux";
                  extra-conf = ''
                    max-jobs = auto
                  '';
                };
              }
              {
                uses = "cachix/cachix-action@v15";
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

  flake.tests.first-ci-kit = import ../module/tests { inherit lib; };

  perSystem =
    { config, pkgs, ... }:
    {
      formatter = config.treefmt.programs.nixfmt.package;

      treefmt = {
        programs.nixfmt = {
          enable = true;
          package = pkgs.nixfmt-rfc-style;
        };
      };

      pre-commit.check.enable = false;
      pre-commit.settings.hooks = {
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

      packages.module-docs = pkgs.callPackage ../packages/module-docs {
        moduleRoot = ../module;
      };
    };
}
