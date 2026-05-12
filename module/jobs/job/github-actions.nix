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

  anyBranch = fn: lib.pipe config.branches [
    builtins.attrValues
    (builtins.any fn)
  ];

  # A job has changes detection if any of its branch configs have changes.paths set.
  hasChanges = anyBranch (b: b.changes.paths != [ ]);

  # A job is MR-only if it has onMergeRequest branches but no onPush branches.
  # Such jobs need an explicit event_name guard so they don't run on push pipelines.
  onlyOnMergeRequest = anyBranch (b: b.triggers.onMergeRequest) && !anyBranch (b: b.triggers.onPush);

  conditions = builtins.concatLists [
    (lib.optional onlyOnMergeRequest "github.event_name == 'pull_request'")
    (lib.optional hasChanges "fromJSON(needs.changes.outputs.changes)['${transformJobName name}'] == true")
    (map (job: "(needs.${job}.result == 'success' || needs.${job}.result == 'skipped')") optionalNeedJobs)
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
        (lib.mkIf config.checkout (
          lib.mkBefore [
            (lib.mergeAttrsList [
              { uses = checkoutAction; }
              (lib.optionalAttrs (config.fetchDepth != null) {
                "with"."fetch-depth" = config.fetchDepth;
              })
            ])
          ]
        ))
        (lib.mkAfter (map (command: { run = command; }) config.commands))
      ];
    }

    (lib.mkIf (conditions != [ ]) {
      "if" = "\${{ ${
        lib.optionalString (optionalNeedJobs != [ ]) "always() && "
      }${lib.concatStringsSep " && " conditions} }}";
    })

    (lib.mkIf (config.artifacts.download != null) {
      steps = lib.mkOrder 600 [
        {
          uses = downloadArtifactAction;
          "with" = lib.mergeAttrsList [
            { inherit (config.artifacts.download) name; }
            (lib.optionalAttrs (config.artifacts.download.path != null) {
              inherit (config.artifacts.download) path;
            })
          ];
        }
      ];
    })

    (lib.mkIf (config.artifacts.upload != null && config.artifacts.upload.paths != [ ]) {
      steps = lib.mkOrder 1600 [
        {
          uses = uploadArtifactAction;
          "with" = lib.mergeAttrsList [
            {
              inherit (config.artifacts.upload) name;
              path = builtins.concatStringsSep "\n" config.artifacts.upload.paths;
            }
            (lib.optionalAttrs (config.artifacts.upload.retentionDays != null) {
              retention-days = config.artifacts.upload.retentionDays;
            })
          ];
        }
      ];
    })

    (lib.mkIf (config.pipelineCall != null) (
      lib.mkMerge [
        {
          uses = "./.github/workflows/${config.pipelineCall.pipeline}.yml";
          "with" = lib.mergeAttrsList [
            config.pipelineCall.inputs
            config.pipelineCall."github-actions".extraInputs
            (lib.optionalAttrs hasChanges {
              changes = "\${{ needs.changes.outputs.changes }}";
              changes_key = transformJobName name;
            })
          ];
        }
        (lib.mkIf config.pipelineCall."github-actions".passSecrets { secrets = "inherit"; })
      ]
    ))
  ];
}
