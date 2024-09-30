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
        };
    };
}
