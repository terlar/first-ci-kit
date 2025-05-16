{
  description = "first-ci-kit - flake-parts module for CI integration";

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs =
    inputs:
    let
      flakeModules = {
        default = ./flake-module.nix;
        git-hooks = ./extra/git-hooks.nix;
        process-compose = ./extra/process-compose.nix;
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ ];

      imports = [
        inputs.flake-parts.flakeModules.partitions
        flakeModules.default
        flakeModules.git-hooks
      ];

      partitionedAttrs = {
        devShells = "dev";
        packages = "dev";
        legacyPackages = "dev";
        formatter = "dev";
        checks = "dev";
        tests = "dev";
      };

      partitions.dev = {
        extraInputsFlake = ./dev;
        module.imports = [ ./dev/flake-module.nix ];
      };

      flake = {
        templates = rec {
          default = dual-project;
          dual-project = {
            path = ./template/dual-project;
            description = ''
              A flake project using first-ci-kit with dual GitHub Actions/GitLab CI pipelines.
            '';
          };
        };

        flakeModule = flakeModules.default;
        inherit flakeModules;
      };
    };
}
