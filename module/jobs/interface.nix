{ config, lib, ... }:

let
  inherit (lib) types;
in
{
  options.jobs = lib.mkOption {
    type = types.lazyAttrsOf (
      types.submoduleWith {
        description = "Job configuration";
        modules = [ ./job ];
        specialArgs.rootConfig = config;
      }
    );
    default = { };
    description = ''
      Jobs to run in this pipeline. Each attribute name becomes the job
      identifier used in backend output (`jobs:` in GitHub Actions,
      job keys in GitLab CI).
    '';
    example = lib.literalExpression ''
      {
        build = {
          image = "nixos/nix:latest";
          script = [ "nix build" ];
          tags = [ "linux" ];
        };
        test = {
          image = "nixos/nix:latest";
          needs = [ "build" ];
          script = [ "nix flake check" ];
        };
      }
    '';
  };
}
