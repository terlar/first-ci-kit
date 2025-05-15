{
  description = "first-ci-kit - flake-parts module for CI integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];

      imports = [
        inputs.flake-parts.flakeModules.partitions
        ./flake-module.nix
      ];

      partitionedAttrs = {
        devShells = "dev";
        packages = "dev";
        legacyPackages = "dev";
        formatter = "dev";
        checks = "dev";
        tests = "dev";
        debug = "dev";
        currentSystem = "dev";
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
        flakeModule = ./flake-module.nix;
      };
    };
}
