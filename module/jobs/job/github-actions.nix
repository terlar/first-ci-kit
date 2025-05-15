{
  lib,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) jobs;
  inherit (rootConfig.pipeline.github-actions) defaultRunsOn transformJobName;

  needs = lib.pipe config.needs [
    (builtins.filter (need: jobs.${need.job}.enable))
    (builtins.catAttrs "job")
    (map transformJobName)
  ];
in
{
  imports = [ ./interface.nix ];

  config.github-actions = {
    needs = lib.mkIf (needs != [ ]) needs;

    runs-on = lib.mkIf (defaultRunsOn != null) (lib.mkDefault defaultRunsOn);

    steps = lib.mkMerge [
      (lib.mkIf config.checkout (lib.mkBefore [ { uses = "actions/checkout@v4"; } ]))
      (lib.mkAfter (map (command: { run = command; }) config.commands))
    ];
  };
}
