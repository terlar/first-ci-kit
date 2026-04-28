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

    rules = lib.pipe config.branches [
      (lib.mapAttrsToList (
        name: cfg:
        let
          branchRef = ci-lib.mkBranchRef name;
          branch = ci-lib.resolveBranchName name;

          pathsFromTriggers = lib.pipe config.triggers [
            (builtins.filter (job: jobs ? ${job} && jobs.${job}.enable && jobs.${job}.gitlab-ci.enable))
            (map (job: jobs.${job}.branches.${name}.changes.paths))
            builtins.concatLists
            lib.unique
          ];
          paths = cfg.changes.paths ++ pathsFromTriggers;
        in
        lib.mkAfter [
          (lib.mkIf cfg.triggers.onMergeRequest {
            "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == ${branchRef}";
            changes = lib.mkIf (paths != [ ]) {
              inherit paths;
              compare_to = branch;
            };
          })
          (lib.mkIf cfg.triggers.onPush {
            "if" = "$CI_COMMIT_BRANCH == ${branchRef}";
            changes = lib.mkIf (paths != [ ]) {
              inherit paths;
            };
          })
        ]
      ))
      lib.mkMerge
    ];

    variables = lib.mkMerge [
      (lib.mkIf (!config.checkout) {
        GIT_CHECKOUT = lib.boolToString config.checkout;
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
