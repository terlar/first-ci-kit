{ lib, inputs, ... }:

{
  imports = [ inputs.dev-flake.flakeModule ];

  dev.name = "terlar/first-ci-kit";

  # Dogfood
  first-ci-kit.pipelines = {
    pr = {
      pipeline.github-actions.settings = {
        name = "CI";
        on.push = {
          branches = [ "main" ];
        };
        on.pull_request = {
          branches = [ "main" ];
        };
      };

      jobs = {
        check = {
          checkout = true;

          github-actions = {
            runs-on = "ubuntu-latest";
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

      pre-commit.settings.hooks = {
        generate-module-docs = {
          enable = true;
          stages = [ "pre-push" ];

          name = "generate-module-docs";
          description = "Generate first-ci-kit module documentation.";
          entry =
            let
              app = pkgs.writeShellApplication {
                name = "generate-module-docs";
                text = ''
                  nix build --extra-experimental-features 'nix-command flakes' \
                      --out-link result-module-docs \
                      .#module-docs
                  cp -f result-module-docs module/README.md
                '';
              };
            in
            "${app}/bin/generate-module-docs";

          files = "^module/.*\\.nix$";
        };

        generate-github-actions = {
          enable = true;
          name = "generate-github-actions";
          description = "Generate `.github/workflows/ci.yaml";

          stages = [ "pre-push" ];
          files = "^dev/flake-module.nix$";
          pass_filenames = false;

          entry =
            (pkgs.writeShellScript "generate-github-actions" ''
              set -o errexit
              nix build --extra-experimental-features 'nix-command flakes' \
                --out-link result-github-actions \
                .#ci-pipeline-github-actions-pr

              mkdir -p .github/workflows
              ${pkgs.yq-go}/bin/yq --prettyPrint --output-format yaml result-github-actions > .github/workflows/ci.yaml
            '').outPath;
        };
      };

      packages.module-docs = pkgs.callPackage ../packages/module-docs {
        moduleRoot = ../module;
      };
    };
}
