{ inputs, ... }:

{
  imports = [ inputs.dev-flake.flakeModule ];

  dev.name = "terlar/first-ci-kit";

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
    };
}
