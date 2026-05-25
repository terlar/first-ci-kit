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
    componentPath:
    let
      deploymentNames = discoverDeployments componentPath;
      componentConfig = discoverComponentConfig componentPath;
    in
    lib.mkMerge [
      { deployments = lib.mkDefault (lib.genAttrs deploymentNames (_: { })); }
      componentConfig
    ];

  mkStack = stackPath: {
    components = lib.pipe stackPath [
      subdirs
      (lib.filter (name: isComponent "${stackPath}/${name}"))
      (lib.flip lib.genAttrs (component: mkComponent "${stackPath}/${component}"))
    ];
  };

  discoveredStacks =
    if cfg.stackName != null then
      { ${cfg.stackName} = lib.mkDefault (mkStack cfg.path); }
    else
      lib.pipe cfg.path [
        subdirs
        (lib.filter (s: !builtins.elem s cfg.excludeDirs))
        (lib.flip lib.genAttrs (stack: mkStack "${cfg.path}/${stack}"))
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
    };
  };

  config = lib.mkIf (cfg.enable && builtins.pathExists cfg.path) {
    stacks = discoveredStacks;
  };
}
