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

  nameLines = _id: name: {
    start = "echo '${builtins.replaceStrings [ "'" ] [ "'\\''" ] name}'";
    end = "";
  };

  stepLines = ci-lib.stepBlocks.toShellLines {
    blocks = rootConfig.stepBlocks;
    inherit nameLines;
  } config.steps;

  commandLines = stepLines ++ config.commands;
in
{
  imports = [ ./interface.nix ];

  config.process-compose = lib.mkMerge [
    (lib.mkIf (commandLines != [ ]) {
      command = lib.concatStringsSep "\n" commandLines;
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
