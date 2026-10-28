{ lib, ... }:

{
  # internal/visible=false keeps this out of the main docs: the submodule
  # embeds the core pipeline module (../core) so child pipelines can be evaluated as
  # independent instances, which would duplicate the entire option tree under
  # pipelines.<name>.*. Child-pipeline-specific options are documented by a
  # separate eval of pipelines/pipeline/interface.nix in packages/module-docs.
  options.pipelines = lib.mkOption {
    internal = true;
    visible = false;
    type = lib.types.lazyAttrsOf (
      lib.types.submoduleWith {
        modules = [
          # Children get the core pipeline module only, without this option:
          # dispatch targets are only generated for top-level pipelines, so
          # nesting (pipelines.x.pipelines.y) is not supported.
          ../core
          ./pipeline/interface.nix
        ];
      }
    );
    default = { };
    description = ''
      Nested child pipelines. Each entry is evaluated as an independent pipeline
      instance with its own jobs, jobSets, and backend settings. The parent
      pipeline automatically generates dispatch jobs for each child.

      Only top-level pipelines may declare children; nesting below that is not
      supported.
    '';
  };
}
