{ lib, config, ... }:

let
  needToJobSetName =
    currentStack: deployment: need:
    let
      inherit (need) component;
      stack = if need.stack != null then need.stack else currentStack;
    in
    config.formatJobName ([ stack ] ++ lib.optional (component != null) component ++ [ deployment ]);

  resolveJobFactory =
    stack: stackConfig: componentConfig:
    lib.findFirst (x: x != null)
      (throw "stacks: no jobFactory set for stack '${stack}' and no defaultJobFactory configured")
      [
        componentConfig.jobFactory
        stackConfig.jobFactory
        config.defaultJobFactory
      ];

  allTriples = lib.concatMap (
    stack:
    let
      stackConfig = config.stacks.${stack};
    in
    lib.concatMap (
      component:
      let
        componentConfig = stackConfig.components.${component};
        factoryName = resolveJobFactory stack stackConfig componentConfig;
        deployments =
          if componentConfig.deployments != null then
            componentConfig.deployments
          else
            stackConfig.deployments;
      in
      map (deployment: {
        inherit
          stack
          component
          deployment
          factoryName
          ;
        inherit (config) formatJobName;

        settings = {
          inherit (componentConfig) extraPaths;
        }
        // deployments.${deployment};

        needs = map (need: {
          jobSet = needToJobSetName stack deployment need;
        }) componentConfig.needs;
      }) (builtins.attrNames deployments)
    ) (builtins.attrNames stackConfig.components)
  ) (builtins.attrNames config.stacks);
in
{
  imports = [
    ./interface.nix
    ./discover.nix
  ];

  config.jobFactories = lib.pipe allTriples [
    (map (args: {
      ${args.factoryName}.applications = [ args ];
    }))
    lib.mkMerge
  ];
}
