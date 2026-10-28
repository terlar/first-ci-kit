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

  options.componentPipelines = lib.mkOption {
    type = types.lazyAttrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            module = lib.mkOption {
              type = types.deferredModule;
              default = { };
              description = ''
                Pipeline module imported into every generated pipeline. The
                component name is available as the `component` module argument.
              '';
            };
            stackDiscovery = lib.mkOption {
              type = types.attrs;
              description = ''
                `stackDiscovery` settings used both to list components and in
                each generated pipeline. `stackName` must be set.
              '';
            };
            name = lib.mkOption {
              type = types.functionTo types.str;
              default = component: "${name}-${component}";
              defaultText = lib.literalExpression ''component: "''${prefix}-''${component}"'';
              description = "Pipeline name for a component.";
            };
          };
        }
      )
    );
    default = { };
    description = ''
      Fan out one top-level pipeline per component found by stack discovery.
      Each pipeline has `stackDiscovery.includeComponents = [ component ]`.
    '';
  };
}
