{ lib, ... }:

let
  inherit (lib) types;
in
{
  options.pipelines = lib.mkOption {
    # Element modules are added in ./default.nix; declaring the type without
    # them here lets the docs evaluate this interface without the whole
    # pipeline option tree.
    type = types.lazyAttrsOf (types.submoduleWith { modules = [ ]; });
    default = { };
    description = ''
      Top-level pipelines. Each entry accepts every per-pipeline option and
      renders to its own CI file (e.g. `.github/workflows/<name>.yml`).
    '';
  };
}
