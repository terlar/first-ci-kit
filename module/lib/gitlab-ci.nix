{ lib }:

let
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

  # Pre-compute substitution context for bulk operations (many values with same inputs).
  # Returns a function that applies substitution without recomputing maps each time.
  # Useful for mkInlineJobs where 20-50+ fields need substitution.
  mkSubstituteContext =
    inputs:
    let
      stringInputKeys = lib.pipe inputs [
        lib.attrNames
        (lib.filter (k: builtins.isString inputs.${k}))
      ];
      froms = lib.map (k: "$[[ inputs.${k} ]]") stringInputKeys;
      tos = lib.map (k: inputs.${k}) stringInputKeys;

      tokenPattern = ''^\$[[][[] inputs\.([A-Za-z_][A-Za-z0-9_]*) []][]]$'';

      extractToken =
        elem:
        if builtins.isString elem then
          lib.pipe elem [
            (builtins.match tokenPattern)
            (m: if m != null then lib.head m else null)
          ]
        else
          null;

      substitute =
        v:
        if builtins.isString v then
          let
            token = extractToken v;
            resolved = if token != null then inputs.${token} or null else null;
          in
          if resolved != null then substitute resolved else lib.replaceStrings froms tos v
        else if builtins.isList v then
          lib.concatMap (
            elem:
            let
              token = extractToken elem;
              resolved = if token != null then inputs.${token} or null else null;
            in
            if builtins.isList resolved then lib.map substitute resolved else [ (substitute elem) ]
          ) v
        else if builtins.isAttrs v then
          lib.mapAttrs (_: substitute) v
        else
          v;
    in
    substitute;
in
{
  inherit
    resolveBranchName
    mkBranchRef
    mkSubstituteContext
    ;

  # augmentBranchesWithTriggers: merge changed-path rules from trigger jobs
  # into a job's own branches config.
  #
  # Arguments:
  #   branches : the job's `branches` attrset (from NixOS module evaluation)
  #   triggers : list of job names (strings) that should trigger this job
  #   jobs     : the full `jobs` attrset from root config
  #
  # For each branch, all `changes.paths` from enabled trigger jobs are merged
  # (deduplicated) into the job's own `changes.paths` for that branch.
  #
  # Trigger jobs only need to be enabled at the job level (`enable == true`);
  # they do NOT need to have `gitlab-ci.enable == true`. This allows pipelineCall
  # jobs (whose `gitlab-ci.enable` is forced to `false`) to act as triggers.
  augmentBranchesWithTriggers =
    {
      branches,
      triggers,
      jobs,
    }:
    lib.mapAttrs (
      name: cfg:
      let
        pathsFromTriggers = lib.pipe triggers [
          (lib.filter (
            job:
            jobs ? ${job}
            && jobs.${job}.enable
            && (jobs.${job}.gitlab-ci.enable || jobs.${job}.pipelineCall != null)
          ))
          (map (job: jobs.${job}.branches.${name}.changes.paths))
          builtins.concatLists
          lib.unique
        ];
      in
      lib.recursiveUpdate cfg { changes.paths = lib.unique (cfg.changes.paths ++ pathsFromTriggers); }
    ) branches;

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
