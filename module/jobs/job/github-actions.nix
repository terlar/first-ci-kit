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

  translatePath =
    s:
    let
      # Include workflow-level env keys (e.g. from pipeline inputs via autoEnvInputs,
      # or manually set by the user) in addition to job-level env keys.
      # Sort longest-first so that e.g. STACK_REGION is replaced before STACK,
      # preventing a shorter name from matching inside a longer one.
      varNames = lib.pipe [
        config.env
        (rootConfig.github-actions.settings.env or { })
      ] [
        (map builtins.attrNames)
        lib.flatten
        lib.lists.unique
        (builtins.sort (a: b: builtins.stringLength a > builtins.stringLength b))
      ];
    in
    builtins.foldl' (
      acc: varName:
      let
        replacement = "\${{ env.${varName} }}";
      in
      builtins.replaceStrings [ "\$${varName}" "\${${varName}}" ] [ replacement replacement ] acc
    ) s varNames;

  needs = lib.pipe config.needs [
    (builtins.filter (need: isEnabledJob need.job))
    (map (need: need // { job = resolveJobName need.job; }))
  ];

  needJobs = builtins.catAttrs "job" needs;
  optionalNeedJobs = lib.pipe needs [
    (builtins.filter (need: need.optional))
    (builtins.catAttrs "job")
  ];
  requiredNeedJobs = lib.pipe needs [
    (builtins.filter (need: !need.optional))
    (builtins.catAttrs "job")
  ];

  anyBranch =
    fn:
    lib.pipe config.branches [
      builtins.attrValues
      (builtins.any fn)
    ];

  # A job has changes detection if any of its branch configs have changes.paths set.
  hasChanges = anyBranch (b: b.changes.paths != [ ]);

  # A job is MR-only if it has onMergeRequest branches but no onPush branches.
  # Such jobs need an explicit event_name guard so they don't run on push pipelines.
  onlyOnMergeRequest = anyBranch (b: b.triggers.onMergeRequest) && !anyBranch (b: b.triggers.onPush);

  # Whether always() must be prepended to the if condition.
  needsAlways = optionalNeedJobs != [ ] || config.runAlways;

  conditions = builtins.concatLists [
    (lib.optional onlyOnMergeRequest "github.event_name == 'pull_request'")
    (lib.optional hasChanges "fromJSON(needs.changes.outputs.changes)['${transformJobName name}'] == true")
    (map (
      job: "(needs.${job}.result == 'success' || needs.${job}.result == 'skipped')"
    ) optionalNeedJobs)
    # runAlways: run even on failure, but guard required needs against 'skipped'
    # so the job doesn't run when its dependencies were never triggered (e.g. on PRs).
    (lib.optionals config.runAlways (map (job: "needs.${job}.result != 'skipped'") requiredNeedJobs))
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

    (lib.mkIf (config.env != { }) {
      env = lib.mapAttrs (_: lib.mkDefault) config.env;
    })

    (lib.mkIf (conditions != [ ]) {
      "if" =
        "\${{ ${lib.optionalString needsAlways "always() && "}${lib.concatStringsSep " && " conditions} }}";
    })

    (lib.mkIf (config.artifacts.download != null) {
      steps = lib.mkOrder 600 [
        {
          uses = downloadArtifactAction;
          "with" = lib.mergeAttrsList [
            { inherit (config.artifacts.download) name; }
            (lib.optionalAttrs (config.artifacts.download.path != null) {
              path = translatePath config.artifacts.download.path;
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
              path = builtins.concatStringsSep "\n" (map translatePath config.artifacts.upload.paths);
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
