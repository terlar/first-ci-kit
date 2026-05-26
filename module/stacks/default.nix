{ lib, config, ... }:

let
  # Returns a list of jobSet names for a single need.
  # Two outcomes:
  # - matchDeployment set: one name per target deployment whose `environment`
  #   matches (null = same as current deployment's environment).
  # - matchDeployment null: a single name resolved by `deployment` field
  #   (or the current deployment name when that is also null).
  needToJobSetNames =
    currentStack: deployment: currentDeploymentSettings: need:
    let
      inherit (need) component;
      stack = if need.stack != null then need.stack else currentStack;

      mkName =
        dep: config.formatJobName ([ stack ] ++ lib.optional (component != null) component ++ [ dep ]);

      stackCfg = config.stacks.${stack} or null;
      compCfg =
        if stackCfg != null && component != null then stackCfg.components.${component} or null else null;

      targetDeployments = lib.findFirst (x: x != null) { } (
        lib.optional (compCfg != null) compCfg.deployments
        ++ lib.optional (stackCfg != null && (component == null || compCfg != null)) stackCfg.deployments
      );

      matchByEnvironment =
        let
          filterEnv = need.matchDeployment.environment;
          expectedEnv =
            if filterEnv == null then currentDeploymentSettings.environment or null else filterEnv;
          matches = dep: (targetDeployments.${dep}.environment or null) == expectedEnv;
        in
        lib.pipe targetDeployments [
          builtins.attrNames
          (builtins.filter matches)
          (map mkName)
        ];

      resolveByName = [ (mkName (if need.deployment != null then need.deployment else deployment)) ];
    in
    if need.matchDeployment != null then matchByEnvironment else resolveByName;

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
        mkNeed = jobSet: { inherit jobSet; };
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

        needs = lib.concatMap (
          need: map mkNeed (needToJobSetNames stack deployment deployments.${deployment} need)
        ) componentConfig.needs;
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
