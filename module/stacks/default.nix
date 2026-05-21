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
    stackName: stack:
    if stack.jobFactory != null then
      stack.jobFactory
    else if config.defaultJobFactory != null then
      config.defaultJobFactory
    else
      throw "stacks: no jobFactory set for stack '${stackName}' and no defaultJobFactory configured";

  allTriples = lib.concatMap (
    stackName:
    let
      stack = config.stacks.${stackName};
      factoryName = resolveJobFactory stackName stack;
    in
    lib.concatMap (
      componentName:
      map (deployment: {
        inherit
          stack
          stackName
          componentName
          deployment
          factoryName
          ;
        inherit (config) formatJobName;
        component = stack.components.${componentName};
        needs = map (need: {
          jobSet = needToJobSetName stackName deployment need;
        }) stack.components.${componentName}.needs;
      }) (builtins.attrNames stack.deployments)
    ) (builtins.attrNames stack.components)
  ) (builtins.attrNames config.stacks);
in
{
  imports = [ ./interface.nix ];

  config.jobFactories = lib.mkMerge (
    map (args: {
      ${args.factoryName}.applications = [ args ];
    }) allTriples
  );
}
