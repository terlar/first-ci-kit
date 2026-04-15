{ lib, ... }:

{
  options.pipelines = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submoduleWith {
        modules = [
          ./..
          ./pipeline/interface.nix
          ./pipeline/gitlab-ci-inputs.nix
        ];
      }
    );
    default = { };
    description = ''
      Nested child pipelines. Each entry is evaluated as an independent pipeline
      instance with its own jobs, jobSets, and backend settings. The parent
      pipeline automatically generates dispatch jobs for each child.
    '';
  };
}
