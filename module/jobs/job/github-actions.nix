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

  needs = lib.pipe config.needs [
    (builtins.filter (need: jobs.${need.job}.enable && jobs.${need.job}.github-actions.enable))
    (map (need: need // { job = transformJobName need.job; }))
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

  isCallerJob = config.uses != null;
in
{
  config.github-actions = lib.mkMerge [
    # applies to all jobs (regular and caller)
    { needs = lib.mkIf (needJobs != [ ]) needJobs; }

    (lib.mkIf hasChanges {
      needs = [ "changes" ];
    })

    (lib.mkIf (conditions != [ ]) {
      "if" = "\${{ ${lib.concatStringsSep " && " conditions} }}";
    })

    # forward uses to the github-actions output
    (lib.mkIf isCallerJob {
      inherit (config) uses;
    })

    # only for regular (non-caller) jobs
    (lib.mkIf (!isCallerJob) {
      runs-on = lib.mkIf (defaultRunsOn != null) (lib.mkDefault defaultRunsOn);

      steps = lib.mkMerge [
        (lib.mkIf config.checkout (lib.mkBefore [ { uses = checkoutAction; } ]))
        (lib.mkAfter (map (command: { run = command; }) config.commands))
      ];
    })

    (lib.mkIf (!isCallerJob && config.artifacts.download != null) {
      steps = lib.mkOrder 600 [
        {
          uses = downloadArtifactAction;
          "with".name = config.artifacts.download.name;
        }
      ];
    })

    (lib.mkIf (!isCallerJob && config.artifacts.upload != null && config.artifacts.upload.paths != [ ])
      {
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
      }
    )
  ];
}
