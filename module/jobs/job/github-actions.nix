{
  lib,
  name,
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
  config.github-actions = lib.mkMerge [
    {
      needs = lib.mkIf (needs != [ ]) needs;

      runs-on = lib.mkIf (defaultRunsOn != null) (lib.mkDefault defaultRunsOn);

      steps = lib.mkMerge [
        (lib.mkIf config.checkout (lib.mkBefore [ { uses = "actions/checkout@v4"; } ]))
        (lib.mkAfter (map (command: { run = command; }) config.commands))
      ];
    }

    (lib.mkIf (config ? branches.default.changes.paths) {
      needs = [ "changes" ];
      "if" = "\${{ fromJSON(needs.changes.outputs.changes)['${name}'] == true }}";
    })
  ];
}
