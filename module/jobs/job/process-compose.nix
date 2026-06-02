{
  lib,
  ci-lib,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) jobs;
  inherit (ci-lib.process-compose) mkDependsOn;

  depends_on = mkDependsOn {
    inherit jobs;
    inherit (config) needs runAlways;
  };
in
{
  imports = [ ./interface.nix ];

  config.process-compose = lib.mkMerge [
    (lib.mkIf (config.commands != [ ]) {
      command = lib.concatStringsSep "\n" config.commands;
    })

    (lib.mkIf (depends_on != { }) {
      inherit depends_on;
    })

    # Map the shared env attrset to process-compose's list format ["KEY=value"].
    (lib.mkIf (config.env != { }) {
      environment = lib.mapAttrsToList (k: v: "${k}=${v}") config.env;
    })
  ];
}
