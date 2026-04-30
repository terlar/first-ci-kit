{
  lib,
  ci-lib,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) imageRegistry jobs;
  inherit (rootConfig.gitlab-ci) defaultStage transformJobName;

  isEnabledJob = name: (jobs.${name}.enable or true) && (jobs.${name}.gitlab-ci.enable or true);
  resolveJobName = name: if jobs ? ${name} then transformJobName name else name;

  needs = lib.pipe config.needs [
    (builtins.filter (need: isEnabledJob need.job))
    (map (need: need // { job = resolveJobName need.job; }))
  ];
in
{
  config.gitlab-ci = {
    enable = lib.mkIf (config.pipelineCall != null) (lib.mkForce false);
    stage = lib.mkIf (defaultStage != null) (lib.mkDefault defaultStage);
    needs = lib.mkIf (needs != [ ]) needs;

    image = lib.mkIf (!builtins.isNull config.image) imageRegistry.${config.image} or config.image;

    rules =
      let
        augmentedBranches = lib.mapAttrs (
          name: cfg:
          let
            pathsFromTriggers = lib.pipe config.triggers [
              (builtins.filter (job: jobs ? ${job} && jobs.${job}.enable && jobs.${job}.gitlab-ci.enable))
              (map (job: jobs.${job}.branches.${name}.changes.paths))
              builtins.concatLists
              lib.unique
            ];
          in
          cfg
          // {
            changes = cfg.changes // {
              paths = lib.unique (cfg.changes.paths ++ pathsFromTriggers);
            };
          }
        ) config.branches;
        inherit (ci-lib.mkBranchRules augmentedBranches) allRules;
      in
      # pipelineCall jobs are suppressed from GitLab CI rendering; branch rules
      # are forwarded via rulesInput/pushRulesInput instead, so we do not append
      # them here to keep job.gitlab-ci.rules to jobDefaults guard rules only.
      lib.mkIf (config.pipelineCall == null && allRules != [ ]) (lib.mkAfter allRules);

    variables = lib.mkMerge [
      (lib.mkIf (!config.checkout) {
        GIT_CHECKOUT = lib.boolToString config.checkout;
      })
      (lib.mkIf (config.fetchDepth != null) {
        GIT_DEPTH = toString config.fetchDepth;
      })
      (lib.mkIf rootConfig.autoEnvInputs (
        lib.mapAttrs' (name: _: {
          name = lib.strings.toUpper name;
          value = "$[[ inputs.${name} ]]";
        }) rootConfig.inputs
      ))
    ];

    script = lib.mkIf (config.commands != [ ]) config.commands;

    artifacts = lib.mkIf (config.artifacts.upload != null) (
      lib.mkDefault (
        let
          inherit (config.artifacts) upload;
          effectiveExpireIn =
            if upload.gitlab-ci.expire_in != null then
              upload.gitlab-ci.expire_in
            else if upload.retentionDays != null then
              "${toString upload.retentionDays} days"
            else
              null;
        in
        lib.mkMerge [
          { public = false; }
          (lib.mkIf (upload.paths != [ ]) { inherit (upload) paths; })
          (lib.mkIf (effectiveExpireIn != null) { expire_in = effectiveExpireIn; })
          (lib.mkIf (upload.gitlab-ci.reports != null) { inherit (upload.gitlab-ci) reports; })
        ]
      )
    );
  };
}
