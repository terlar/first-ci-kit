{ lib, config, ... }:

let
  inherit (lib) types;
  cfg = config.stackDiscovery;

  subdirs =
    path:
    lib.pipe path [
      builtins.readDir
      (lib.filterAttrs (_: type: type == "directory"))
      builtins.attrNames
    ];

  scanPath =
    componentPath:
    if cfg.deployments.subdirectory != null then
      "${componentPath}/${cfg.deployments.subdirectory}"
    else
      componentPath;

  isComponent =
    path:
    let
      entries = builtins.readDir path;
    in
    if cfg.deployments.subdirectory != null then
      (entries.${cfg.deployments.subdirectory} or "") == "directory"
    else if cfg.deployments.detection == "files" then
      builtins.any (lib.hasSuffix cfg.deployments.extension) (builtins.attrNames entries)
    else
      builtins.any (t: t == "directory") (builtins.attrValues entries);

  discoverDeployments =
    componentPath:
    if cfg.deployments.detection == "directories" then
      subdirs (scanPath componentPath)
    else
      lib.pipe (scanPath componentPath) [
        builtins.readDir
        builtins.attrNames
        (lib.filter (lib.hasSuffix cfg.deployments.extension))
        (map (lib.removeSuffix cfg.deployments.extension))
      ];

  discoverComponentConfig =
    componentPath:
    let
      configPath = "${componentPath}/${cfg.component.configFile}";
    in
    if builtins.pathExists configPath then import configPath else { };

  mkComponent =
    stack: path:
    let
      deploymentNames = discoverDeployments path;
      componentConfig = discoverComponentConfig path;
    in
    lib.mkMerge [
      { inherit path stack; }
      {
        deployments = lib.mkDefault (
          lib.genAttrs deploymentNames (
            name: lib.mkDefault { environment = lib.mkDefault (cfg.deployments.environmentFromName name); }
          )
        );
      }
      componentConfig
    ];

  mkStack = stack: stackPath: {
    components = lib.pipe stackPath [
      subdirs
      (lib.filter (name: isComponent "${stackPath}/${name}"))
      (lib.flip lib.genAttrs (name: mkComponent stack "${stackPath}/${name}"))
    ];
  };

  discoveredStacks =
    if cfg.stackName != null then
      { ${cfg.stackName} = lib.mkDefault (mkStack cfg.stackName cfg.path); }
    else
      lib.pipe cfg.path [
        subdirs
        (lib.filter (s: !builtins.elem s cfg.excludeDirs))
        (lib.flip lib.genAttrs (stack: mkStack stack "${cfg.path}/${stack}"))
        (lib.mapAttrs (_: v: lib.mkDefault v))
      ];
in
{
  options.stackDiscovery = {
    enable = lib.mkEnableOption "filesystem-based stack discovery";

    path = lib.mkOption {
      type = types.path;
      description = ''
        Root directory to scan. When `stackName` is null (the default),
        first-level subdirectories become stack names and second-level
        subdirectories that qualify as components become component names.
        When `stackName` is set, `path` is treated as the stack directory
        itself and first-level subdirectories become component names directly.
      '';
      example = lib.literalExpression "./terraform";
    };

    stackName = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        When set, `path` is treated as a single stack with this name.
        First-level subdirectories of `path` become component names directly,
        with no intermediate stack-level directory.

        When null (the default), first-level subdirectories of `path` are
        treated as stack names.
      '';
      example = lib.literalExpression ''"infra"'';
    };

    excludeDirs = lib.mkOption {
      type = types.listOf types.str;
      default = [ "modules" ];
      description = ''
        Subdirectory names to skip during stack-level scanning. Only applies
        when `stackName` is null.
      '';
      example = lib.literalExpression ''[ "modules" "shared" ]'';
    };

    deployments = {
      subdirectory = lib.mkOption {
        type = types.nullOr types.str;
        default = "deployments";
        description = ''
          Subdirectory inside each component that holds deployment entries.
          A component is recognised when this subdirectory exists.

          Set to `null` to scan the component directory itself. In that case
          a directory qualifies as a component when it contains at least one
          entry matching `deployments.detection` (a file with
          `deployments.extension`, or a subdirectory).
        '';
        example = lib.literalExpression "null";
      };

      detection = lib.mkOption {
        type = types.enum [
          "files"
          "directories"
        ];
        default = "directories";
        description = ''
          How deployments are identified inside the scanned directory
          (`deployments.subdirectory`, or the component directory when
          `deployments.subdirectory` is `null`).

          - `"directories"`: each subdirectory is a deployment; the directory
            name becomes the key.
          - `"files"`: each file whose name ends with `deployments.extension`
            is a deployment; the extension is stripped to form the key.
        '';
        example = lib.literalExpression ''"files"'';
      };

      extension = lib.mkOption {
        type = types.str;
        default = ".tfvars";
        description = ''
          File extension used to identify deployment files when
          `deployments.detection` is `"files"`. The basename with this
          extension stripped becomes the deployment key.
        '';
        example = lib.literalExpression ''".tfvars"'';
      };

      environmentFromName = lib.mkOption {
        type = types.functionTo types.str;
        default = name: name;
        description = ''
          Function mapping a discovered deployment directory/file name to the
          logical `environment` value stored on that deployment. Applied to
          every deployment discovered by the filesystem scan.

          The default is the identity function (deployment key = environment).
          Override this when your deployment naming convention encodes the
          environment as a prefix or substring, e.g.:

          ```nix
          environmentFromName = dep: lib.head (lib.splitString "_" dep);
          ```

          This sets `environment = "dev"` for a deployment named `dev_tooling`,
          keeping the env-extraction convention in the consuming repository
          rather than in the upstream library.
        '';
        example = lib.literalExpression ''dep: lib.head (lib.splitString "_" dep)'';
      };
    };

    component = {
      configFile = lib.mkOption {
        type = types.str;
        default = "component.nix";
        description = ''
          Filename within each component directory imported as a plain Nix
          attrset of component options. May set any component option: `needs`,
          `extraPaths`, `jobFactory`, `deployments`, etc. Values from this file
          are applied at normal priority — they win over filesystem-derived
          defaults but lose to explicit hand-written config.

          When the file does not exist the component is discovered with
          filesystem-derived defaults only.
        '';
        example = lib.literalExpression ''"component.nix"'';
      };

      module = lib.mkOption {
        type = types.deferredModule;
        default = { };
        description = ''
          A module merged into every component submodule. Use it to declare
          extra options and set filesystem-derived default values.

          The module receives the following read-only options set by the
          discovery process (`null` for hand-written components):

          - `config.path` — absolute filesystem path to the component directory
          - `config.stack` — name of the containing stack
          - `_module.args.name` — name of the component (standard attrset key)

          Multiple assignments to `component.module` are merged by the NixOS
          module system in the usual way.

          Example — auto-detect a buildable package:

          ```nix
          { config, lib, ... }:
          lib.mkIf (config.path != null) {
            options.hasPackage = lib.mkOption { type = lib.types.bool; default = false; };
            config.hasPackage = lib.mkDefault (builtins.pathExists "''${config.path}/package/default.nix");
          }
          ```
        '';
        example = lib.literalExpression ''
          { config, lib, ... }:
          lib.mkIf (config.path != null) {
            options.hasPackage = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
            config.hasPackage = lib.mkDefault (builtins.pathExists "''${config.path}/package/default.nix");
          }
        '';
      };
    };
  };

  # Inject discovery metadata options and the consumer-supplied defaults module
  # into every component submodule via the binOp on options.stacks.
  options.stacks = lib.mkOption {
    type = types.lazyAttrsOf (
      types.submoduleWith {
        modules = [
          {
            options.components = lib.mkOption {
              type = types.lazyAttrsOf (
                types.submoduleWith {
                  modules = [
                    {
                      options = {
                        path = lib.mkOption {
                          type = types.nullOr types.path;
                          default = null;
                          internal = true;
                          description = "Absolute filesystem path to the component directory. Null for hand-written components.";
                        };
                        stack = lib.mkOption {
                          type = types.nullOr types.str;
                          default = null;
                          internal = true;
                          description = "Name of the containing stack. Null for hand-written components.";
                        };
                      };
                    }
                    cfg.component.module
                  ];
                }
              );
            };
          }
        ];
      }
    );
  };

  config = lib.mkIf (cfg.enable && builtins.pathExists cfg.path) {
    stacks = discoveredStacks;
  };
}
