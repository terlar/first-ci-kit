{
  lib,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig.pipeline.github-actions) defaultRunsOn;
in
{
  imports = [ ./interface.nix ];

  config.github-actions = {
    runs-on = lib.mkIf (defaultRunsOn != null) (lib.mkDefault defaultRunsOn);
    steps = lib.mkMerge [
      (lib.mkIf config.checkout (lib.mkBefore [ { uses = "actions/checkout@v4"; } ]))
      (lib.mkAfter (map (command: { run = command; }) config.commands))
    ];
  };
}
