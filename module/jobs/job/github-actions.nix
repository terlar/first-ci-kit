{
  lib,
  name,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) jobs;
  inherit (rootConfig.github-actions)
    checkoutAction
    defaultRunsOn
    downloadArtifactAction
    transformJobName
    uploadArtifactAction
    ;

  isEnabledJob = name: (jobs.${name}.enable or true) && (jobs.${name}.github-actions.enable or true);
  resolveJobName = name: if jobs ? ${name} then transformJobName name else name;

  needs = lib.pipe config.needs [
    (builtins.filter (need: isEnabledJob need.job))
    (map (need: need // { job = resolveJobName need.job; }))
  ];

  needJobs = builtins.catAttrs "job" needs;
  optionalNeedJobs = lib.pipe needs [
    (builtins.filter (need: need.optional))
    (builtins.catAttrs "job")
  ];

  hasChanges = (config.branches.default.changes.paths or [ ]) != [ ];

  conditions = lib.pipe optionalNeedJobs [
    (map (job: "(needs.${job}.result == 'success' || needs.${job}.result == 'skipped')"))
    (lib.concat (lib.optional hasChanges "fromJSON(needs.changes.outputs.changes)['${name}'] == true"))
  ];
in
{
  config.github-actions = lib.mkMerge [
    {
      needs = lib.mkMerge [
        (lib.mkIf hasChanges [ "changes" ])
        (lib.mkIf (needJobs != [ ]) needJobs)
      ];

      runs-on = lib.mkIf (defaultRunsOn != null) (lib.mkDefault defaultRunsOn);

      steps = lib.mkMerge [
        (lib.mkIf config.checkout (lib.mkBefore [ { uses = checkoutAction; } ]))
        (lib.mkAfter (map (command: { run = command; }) config.commands))
      ];
    }

    (lib.mkIf (conditions != [ ]) {
      "if" = "\${{ ${lib.concatStringsSep " && " conditions} }}";
    })

    (lib.mkIf (config.artifacts.download != null) {
      steps = lib.mkOrder 600 [
        {
          uses = downloadArtifactAction;
          "with" = {
            inherit (config.artifacts.download) name;
          }
          // lib.optionalAttrs (config.artifacts.download.path != null) {
            inherit (config.artifacts.download) path;
          };
        }
      ];
    })

    (lib.mkIf (config.artifacts.upload != null && config.artifacts.upload.paths != [ ]) {
      steps = lib.mkOrder 1600 [
        {
          uses = uploadArtifactAction;
          "with" = {
            inherit (config.artifacts.upload) name;
            path = builtins.concatStringsSep "\n" config.artifacts.upload.paths;
          }
          // lib.optionalAttrs (config.artifacts.upload.retentionDays != null) {
            retention-days = config.artifacts.upload.retentionDays;
          };
        }
      ];
    })
  ];
}
