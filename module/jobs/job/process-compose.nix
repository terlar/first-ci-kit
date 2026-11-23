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
in
{
  imports = [ ./interface.nix ];

  config.process-compose = lib.mkMerge [
    (lib.mkIf (stepLines != [ ] || config.commands != [ ]) {
      command = lib.concatStringsSep "\n" (stepLines ++ config.commands);
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
