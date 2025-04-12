{
  lib,
  rootConfig,
  config,
  ...
}:

let
  inherit (rootConfig) imageRegistry jobs;

  needs = builtins.filter (need: jobs.${need.job}.enable) config.needs;
  triggersBranchConfig = map (job: jobs.${job}.branches) config.triggers;
in
{
  imports = [ ./interface.nix ];

  config = {
    github-actions = {
      steps =
        (lib.optional config.checkout {
          uses = "actions/checkout@v4";
        })
        ++ (map (command: { run = command; }) config.commands);
    };

    gitlab-ci = {
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
          [
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
    };
  };
}
