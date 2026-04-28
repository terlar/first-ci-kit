{ lib, ... }:

let
  inherit (lib) types;

  expandPipelineNeed =
    jobSets: need:
    if need.jobSet != null then
      map (job: {
        inherit job;
        inherit (need) optional artifacts;
      }) jobSets.${need.jobSet}.jobs
    else
      [
        {
          inherit (need) job optional artifacts;
        }
      ];

  # Resolve a branch name, mapping the special "default" name to the GitLab
  # predefined variable $CI_DEFAULT_BRANCH.
  resolveBranchName = name: if name == "default" then "$CI_DEFAULT_BRANCH" else name;

  # Convert a branch name to a GitLab CI `if:` expression operand.
  #
  # "default"     → "$CI_DEFAULT_BRANCH"   (resolved to the GitLab predefined variable)
  # "$SOME_VAR"   → "$SOME_VAR"            (variable references kept as-is)
  # "production"  → "'production'"          (literal names are single-quoted for GitLab CI)
  mkBranchRef =
    name:
    let
      ref = resolveBranchName name;
    in
    if lib.hasPrefix "$" ref then ref else "'${ref}'";
in
{
  documentsToYAML = lib.concatMapStringsSep "---\n" (x: (builtins.toJSON x) + "\n");

  types.needsType = types.submoduleWith {
    description = "Needs configuration";
    modules = [
      {
        options = {
          job = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job.";
          };

          jobSet = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job set.";
          };

          optional = lib.mkOption {
            type = types.bool;
            default = false;
            description = "Whether need is optional.";
          };

          artifacts = lib.mkOption {
            type = types.bool;
            default = true;
            description = "Whether artifacts from dependency are used.";
          };
        };
      }
    ];
  };

  jobToNeed = job: {
    inherit job;
    artifacts = false;
    optional = true;
  };

  # Expand a single pipeline need given a jobSets attrset.
  # Returns a list of { job, optional, artifacts }.
  inherit expandPipelineNeed;

  # Expand a list of pipeline needs into a flat list of { job, optional, artifacts }.
  expandPipelineNeeds = jobSets: needs: lib.flatten (map (expandPipelineNeed jobSets) needs);

  replaceVariables =
    variables:
    let
      from = lib.pipe variables [
        builtins.attrNames
        (map (x: "{${x}}"))
      ];
      to = builtins.attrValues variables;
    in
    map (builtins.replaceStrings from to);

  # Expose helpers so modules (e.g. gitlab-ci.nix) can reuse them via ci-lib.
  inherit resolveBranchName mkBranchRef;

  # mkBranchRules: compute GitLab CI rule objects from a resolved `branches`
  # attrset (as found in job.branches after NixOS module evaluation).
  #
  # Each branch entry is expected to have:
  #   triggers.onMergeRequest : bool
  #   triggers.onPush         : bool
  #   changes.paths           : list of strings
  #
  # Returns { allRules, pushRules } where:
  #   allRules   — MR rules + push rules for all configured branches
  #   pushRules  — push-only rules for all configured branches
  mkBranchRules =
    branches:
    let
      results = lib.mapAttrsToList (
        name: cfg:
        let
          branchRef = mkBranchRef name;
          branchVal = resolveBranchName name;
          changesWithCmp = lib.optionalAttrs (cfg.changes.paths != [ ]) {
            changes = {
              inherit (cfg.changes) paths;
              compare_to = branchVal;
            };
          };
          changesNoCmp = lib.optionalAttrs (cfg.changes.paths != [ ]) {
            changes.paths = cfg.changes.paths;
          };
          mrRule = lib.mergeAttrsList [
            { "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == ${branchRef}"; }
            changesWithCmp
          ];
          pushRule = lib.mergeAttrsList [
            { "if" = "$CI_COMMIT_BRANCH == ${branchRef}"; }
            changesNoCmp
          ];
        in
        {
          allRules =
            lib.optionals cfg.triggers.onMergeRequest [ mrRule ]
            ++ lib.optionals cfg.triggers.onPush [ pushRule ];
          pushRules = lib.optionals cfg.triggers.onPush [ pushRule ];
        }
      ) branches;
    in
    {
      allRules = lib.concatMap (r: r.allRules) results;
      pushRules = lib.concatMap (r: r.pushRules) results;
    };
}
