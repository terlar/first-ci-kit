{
  pkgs,
  lib,
  config,
}:

let
  ghaPathChanges = config.packages.gha-path-changes;

  # Each test case: attrset of env vars to export, plus the expected output.
  # DIFF_PATHS and GITHUB_OUTPUT are provided by the harness.
  testCases = [
    # --- basic event handling ---
    {
      name = "push: svc-a changed";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$HEAD_SHA";
      };
      expected = ''{"svc-a":true,"svc-b":false}'';
    }
    {
      name = "pull_request: svc-a changed";
      env = {
        GITHUB_EVENT_NAME = "pull_request";
        GITHUB_BASE_REF = "main";
        GITHUB_HEAD_REF = "feature";
      };
      expected = ''{"svc-a":true,"svc-b":false}'';
    }
    {
      name = "push: no service changed";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$HEAD_SHA";
        GITHUB_EVENT_AFTER = "$NEW_HEAD";
      };
      expected = ''{"svc-a":false,"svc-b":false}'';
    }
    {
      name = "push: colon in group name, svc-a changed";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$HEAD_SHA";
        DIFF_PATHS = "org:svc-a:services/svc-a/**\norg:svc-b:services/svc-b/**";
      };
      expected = ''{"org:svc-a":true,"org:svc-b":false}'';
    }

    # --- glob pattern matching ---

    # **/\* should match a file directly in the directory (** = zero dirs)
    {
      name = "push: **/* matches single-level file under module";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$MODULE_SHALLOW_SHA";
        DIFF_PATHS = "svc-a:services/svc-a/module/**/*\nsvc-b:services/svc-b/module/**/*";
      };
      expected = ''{"svc-a":true,"svc-b":false}'';
    }

    # **/\* should also match a deeply nested file (** = one subdir)
    {
      name = "push: **/* matches deeply nested file under module (1 subdir)";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$MODULE_DEEP_SHA";
        DIFF_PATHS = "svc-a:services/svc-a/module/**/*\nsvc-b:services/svc-b/module/**/*";
      };
      expected = ''{"svc-a":true,"svc-b":false}'';
    }

    # **/\* should match a file nested 2+ levels deep under module
    {
      name = "push: **/* matches deeply nested file under module (2 subdirs)";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$MODULE_VERY_DEEP_SHA";
        DIFF_PATHS = "svc-a:services/svc-a/module/**/*\nsvc-b:services/svc-b/module/**/*";
      };
      expected = ''{"svc-a":true,"svc-b":false}'';
    }

    # * should NOT match across a directory boundary — diff only the deep commit
    {
      name = "push: * does not match across directory boundary";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$MODULE_SHALLOW_SHA";
        GITHUB_EVENT_AFTER = "$MODULE_DEEP_SHA";
        DIFF_PATHS = "svc-a:services/svc-a/module/*\nsvc-b:services/svc-b/module/*";
      };
      expected = ''{"svc-a":false,"svc-b":false}'';
    }

    # alternation: | should trigger on either branch
    {
      name = "push: alternation matches via second pattern";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$MODULE_SHALLOW_SHA";
        DIFF_PATHS = "svc-a:services/svc-a/config/*|services/svc-a/module/**/*";
      };
      expected = ''{"svc-a":true}'';
    }

    # exact path (no glob) should match only that specific file
    {
      name = "push: exact path matches specific file";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$TAG_SHA";
        DIFF_PATHS = "svc-a:services/svc-a/module/tag";
      };
      expected = ''{"svc-a":true}'';
    }

    {
      name = "push: exact path does not match other files";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$MODULE_SHALLOW_SHA";
        DIFF_PATHS = "svc-a:services/svc-a/module/tag";
      };
      expected = ''{"svc-a":false}'';
    }

    # --- FORCE_RUN_ALL bypass ---
    {
      name = "force_run_all: all groups reported as true, no git ops needed";
      env = {
        FORCE_RUN_ALL = "true";
        # No GITHUB_EVENT_NAME / refs — would fail if git fetch were attempted
      };
      expected = ''{"svc-a":true,"svc-b":true}'';
    }
    {
      name = "force_run_all: empty string does not trigger bypass";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$HEAD_SHA";
        FORCE_RUN_ALL = "";
      };
      expected = ''{"svc-a":true,"svc-b":false}'';
    }
    {
      name = "force_run_all: string 'false' does not trigger bypass";
      env = {
        GITHUB_EVENT_NAME = "push";
        GITHUB_EVENT_BEFORE = "$BASE_SHA";
        GITHUB_EVENT_AFTER = "$HEAD_SHA";
        FORCE_RUN_ALL = "false";
      };
      expected = ''{"svc-a":true,"svc-b":false}'';
    }
  ];

  runCase =
    {
      name,
      env,
      expected,
    }:
    let
      # Values that start with $ are shell variable references — emit them
      # unquoted so the shell expands them at runtime. Static values are
      # single-quoted for safety.
      exportVal = v: if lib.hasPrefix "$" v then v else lib.escapeShellArg v;
      exports = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=${exportVal v}") env);
    in
    ''
      GITHUB_OUTPUT=$(mktemp)
      GITHUB_STEP_SUMMARY=$(mktemp)
      export GITHUB_OUTPUT GITHUB_STEP_SUMMARY
      (
        cd "$repo"
        ${exports}
        gha-path-changes
      )
      actual=$(grep '^changes=' "$GITHUB_OUTPUT" | sed 's/^changes=//')
      if [ "$actual" != ${lib.escapeShellArg expected} ]; then
        echo "FAILED: ${name}"
        echo "  expected: ${expected}"
        echo "  actual:   $actual"
        exit 1
      fi
      echo "PASSED: ${name}"
    '';
in
pkgs.runCommand "test-gha-path-changes"
  {
    nativeBuildInputs = [
      pkgs.git
      ghaPathChanges
    ];
  }
  ''
    set -euo pipefail

    # ---- set up a bare git repo used as origin ----
    origin=$(mktemp -d)
    git init --bare "$origin"

    # ---- set up a working clone ----
    repo=$(mktemp -d)
    git -C "$repo" init
    git -C "$repo" remote add origin "$origin"
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test"
    git -C "$repo" config init.defaultBranch main

    # initial commit on main
    mkdir -p "$repo/services/svc-a/module/subdir" "$repo/services/svc-a/module/a/b" "$repo/services/svc-b/module"
    printf 'init' > "$repo/services/svc-a/file.txt"
    printf 'init' > "$repo/services/svc-b/file.txt"
    printf 'init' > "$repo/services/svc-a/module/main.tf"
    printf 'init' > "$repo/services/svc-a/module/subdir/vars.tf"
    printf 'init' > "$repo/services/svc-a/module/a/b/deep.tf"
    printf 'init' > "$repo/services/svc-a/module/tag"
    git -C "$repo" add .
    git -C "$repo" commit -m "initial"
    git -C "$repo" branch -M main
    git -C "$repo" push origin main
    BASE_SHA=$(git -C "$repo" rev-parse HEAD)

    # second commit: only svc-a/file.txt changes (used by basic event tests)
    printf 'changed' > "$repo/services/svc-a/file.txt"
    git -C "$repo" add .
    git -C "$repo" commit -m "change svc-a"
    git -C "$repo" push origin main
    HEAD_SHA=$(git -C "$repo" rev-parse HEAD)

    # feature branch diverging from BASE_SHA with a different svc-a change
    git -C "$repo" checkout -b feature "$BASE_SHA"
    printf 'feature-change' > "$repo/services/svc-a/file.txt"
    git -C "$repo" add .
    git -C "$repo" commit -m "change svc-a on feature"
    git -C "$repo" push origin feature
    git -C "$repo" checkout main

    # unrelated commit (neither service touched)
    printf 'unrelated' > "$repo/other.txt"
    git -C "$repo" add .
    git -C "$repo" commit -m "unrelated change"
    git -C "$repo" push origin main
    NEW_HEAD=$(git -C "$repo" rev-parse HEAD)

    # commit touching svc-a/module/main.tf (single-level under module)
    printf 'changed' > "$repo/services/svc-a/module/main.tf"
    git -C "$repo" add .
    git -C "$repo" commit -m "change svc-a module shallow"
    git -C "$repo" push origin main
    MODULE_SHALLOW_SHA=$(git -C "$repo" rev-parse HEAD)

    # commit touching svc-a/module/subdir/vars.tf (one level deep under module)
    printf 'changed' > "$repo/services/svc-a/module/subdir/vars.tf"
    git -C "$repo" add .
    git -C "$repo" commit -m "change svc-a module deep"
    git -C "$repo" push origin main
    MODULE_DEEP_SHA=$(git -C "$repo" rev-parse HEAD)

    # commit touching svc-a/module/a/b/deep.tf (two levels deep under module)
    printf 'changed' > "$repo/services/svc-a/module/a/b/deep.tf"
    git -C "$repo" add .
    git -C "$repo" commit -m "change svc-a module very deep"
    git -C "$repo" push origin main
    MODULE_VERY_DEEP_SHA=$(git -C "$repo" rev-parse HEAD)

    # commit touching only svc-a/module/tag (exact-path test)
    printf 'v2' > "$repo/services/svc-a/module/tag"
    git -C "$repo" add .
    git -C "$repo" commit -m "bump svc-a tag"
    git -C "$repo" push origin main
    TAG_SHA=$(git -C "$repo" rev-parse HEAD)

    export DIFF_PATHS="svc-a:services/svc-a/**
    svc-b:services/svc-b/**"

    ${lib.concatMapStrings runCase testCases}

    echo "All gha-path-changes tests passed" > "$out"
  ''
