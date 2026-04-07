{
  lib,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) jobs;

  depends_on = lib.pipe config.needs [
    (builtins.filter (need: jobs.${need.job}.enable && jobs.${need.job}.process-compose.enable))
    (builtins.catAttrs "job")
    (lib.flip lib.genAttrs (_: {
      condition = "process_completed_successfully";
    }))
  ];
in
{
  imports = [ ./interface.nix ];

  config.process-compose = lib.mkIf config.enable {
    inherit depends_on;

    command = builtins.concatStringsSep "\n" config.commands;
  };
}
