{
  lib,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) imageRegistry jobs;
  inherit (rootConfig.pipeline.gitlab-ci) defaultStage transformJobName;

  needs = lib.pipe config.needs [
    (builtins.filter (need: jobs.${need.job}.enable && jobs.${need.job}.gitlab-ci.enable))
    (map (need: need // { job = transformJobName need.job; }))
  ];
  triggersBranchConfig = map (job: jobs.${job}.branches) config.triggers;
in
{
  config.gitlab-ci = {
    stage = lib.mkIf (defaultStage != null) (lib.mkDefault defaultStage);
    needs = lib.mkIf (needs != [ ]) needs;

    image = lib.mkIf (!builtins.isNull config.image) imageRegistry.${config.image} or config.image;

    rules = lib.pipe config.branches [
      (lib.mapAttrsToList (
        name: cfg:
        let
          branch = if name == "default" then "$CI_DEFAULT_BRANCH" else name;
          branchCompare = if lib.hasPrefix "$" branch then branch else "'${branch}'";

          pathsFromTriggers = lib.pipe triggersBranchConfig [
            (map (cfg: cfg.${name}.changes.paths))
            builtins.concatLists
            lib.unique
          ];
          paths = cfg.changes.paths ++ pathsFromTriggers;
        in
        lib.mkAfter [
          (lib.mkIf cfg.triggers.onMergeRequest {
            "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == ${branchCompare}";
            changes = lib.mkIf (paths != [ ]) {
              inherit paths;
              compare_to = branch;
            };
          })
          (lib.mkIf cfg.triggers.onPush {
            "if" = "$CI_COMMIT_BRANCH == ${branchCompare}";
            changes = lib.mkIf (paths != [ ]) {
              inherit paths;
            };
          })
        ]
      ))
      lib.mkMerge
    ];

    variables = lib.mkIf (!config.checkout) {
      GIT_CHECKOUT = lib.boolToString config.checkout;
    };

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
        {
          public = false;
        }
        // lib.optionalAttrs (upload.paths != [ ]) {
          inherit (upload) paths;
        }
        // lib.optionalAttrs (effectiveExpireIn != null) {
          expire_in = effectiveExpireIn;
        }
        // lib.optionalAttrs (upload.gitlab-ci.reports != null) {
          inherit (upload.gitlab-ci) reports;
        }
      )
    );
  };
}
