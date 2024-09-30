{
  lib,
  config,
  ...
}:

{
  imports = [ ./interface.nix ];

  config = {
    gitlab-ci = {
      needs = lib.mkIf (config.needs != [ ]) config.needs;

      image = lib.mkIf (!builtins.isNull config.image) config.image;

      rules = lib.pipe config.branches [
        (lib.mapAttrsToList (
          name: cfg:
          let
            branch = if name == "default" then "$CI_DEFAULT_BRANCH" else name;
            branchCompare = if lib.hasPrefix "$" branch then branch else "'${branch}'";
          in
          [
            (lib.mkIf cfg.triggers.onMergeRequest {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == ${branchCompare}";
              changes = lib.mkIf (cfg.changes.paths != [ ]) {
                inherit (cfg.changes) paths;
                compare_to = "refs/heads/${branch}";
              };
            })
            (lib.mkIf cfg.triggers.onPush {
              "if" = "$CI_COMMIT_BRANCH == ${branchCompare}";
              changes = lib.mkIf (cfg.changes.paths != [ ]) {
                inherit (cfg.changes) paths;
              };
            })
          ]
        ))
        lib.mkMerge
      ];
    };
  };
}
