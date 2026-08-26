{ lib, ... }:

{
  # internal/visible=false keeps this out of generated docs: the submodule
  # embeds the full root module (./..), so rendering would duplicate the entire
  # option tree under pipelines.<name>.* and overflow the docs walker.
  options.pipelines = lib.mkOption {
    internal = true;
    visible = false;
    type = lib.types.lazyAttrsOf (
      lib.types.submoduleWith {
        modules = [
          ./..
          ./pipeline/interface.nix
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
