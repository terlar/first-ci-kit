{ inputs, ... }:

{
  imports = [
    inputs.dev-flake.flakeModule
    inputs.first-ci-kit.flakeModule
    ./ci.nix
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
