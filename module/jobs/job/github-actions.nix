{
  lib,
  name,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) jobs;
  inherit (rootConfig.pipeline.github-actions) defaultRunsOn transformJobName checkoutAction;

  needs = lib.pipe config.needs [
    (builtins.filter (need: jobs.${need.job}.enable && jobs.${need.job}.github-actions.enable))
    (builtins.catAttrs "job")
    (map transformJobName)
  ];
in
{
  config.github-actions = lib.mkIf config.enable (
    lib.mkMerge [
      {
        needs = lib.mkIf (needs != [ ]) needs;

        runs-on = lib.mkIf (defaultRunsOn != null) (lib.mkDefault defaultRunsOn);

        steps = lib.mkMerge [
          (lib.mkIf config.checkout (lib.mkBefore [ { uses = checkoutAction; } ]))
          (lib.mkAfter (map (command: { run = command; }) config.commands))
        ];
      }

      (lib.mkIf ((config.branches.default.changes.paths or [ ]) != [ ]) {
        needs = [ "changes" ];
        "if" = "\${{ fromJSON(needs.changes.outputs.changes)['${name}'] == true }}";
      })
    ]
  );
}
