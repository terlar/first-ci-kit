{ inputs, ... }:

{
  imports = [
    inputs.dev-flake.flakeModule
    inputs.first-ci-kit.flakeModules.default
    inputs.first-ci-kit.flakeModules.git-hooks
    inputs.first-ci-kit.flakeModules.process-compose
    inputs.process-compose.flakeModule
    ./ci.nix
  ];

  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-darwin"
    "x86_64-linux"
  ];

  dev.name = "my-project";

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
        first-ci-kit-gen-github-actions = {
          enable = true;
          files = "^dev/ci.nix$";
        };

        first-ci-kit-gen-gitlab-ci = {
          enable = true;
          files = "^dev/ci.nix$";
        };
      };
    };
}
