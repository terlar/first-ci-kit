{
  lib,
  nixosOptionsDoc,
  pkgs,
  # Args
  moduleRoot,
  extraModules ? [ ],
}:
let
  eval = lib.evalModules {
    specialArgs = {
      inherit pkgs;
    };
    modules = [
      { options._module.args = lib.mkOption { internal = true; }; }
      moduleRoot
    ] ++ extraModules;
  };
  doc = nixosOptionsDoc {
    inherit (eval) options;

    transformOptions =
      opt:
      opt
      // {
        declarations = map (
          decl:
          if lib.hasPrefix (toString moduleRoot) (toString decl) then
            let
              subpath = lib.removePrefix "/" (lib.removePrefix (toString moduleRoot) (toString decl));
            in
            {
              url = subpath;
              name = subpath;
            }
          else
            decl
        ) opt.declarations;
      };
  };
in
doc.optionsCommonMark
