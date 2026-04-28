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
      export GITHUB_OUTPUT
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
    mkdir -p "$repo/services/svc-a" "$repo/services/svc-b"
    printf 'init' > "$repo/services/svc-a/file.txt"
    printf 'init' > "$repo/services/svc-b/file.txt"
    git -C "$repo" add .
    git -C "$repo" commit -m "initial"
    git -C "$repo" branch -M main
    git -C "$repo" push origin main
    BASE_SHA=$(git -C "$repo" rev-parse HEAD)

    # second commit on main: only svc-a changes
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

    # unrelated commit on main (neither service touched)
    printf 'unrelated' > "$repo/other.txt"
    git -C "$repo" add .
    git -C "$repo" commit -m "unrelated change"
    git -C "$repo" push origin main
    NEW_HEAD=$(git -C "$repo" rev-parse HEAD)

    export DIFF_PATHS="svc-a:services/svc-a/**
    svc-b:services/svc-b/**"

    ${lib.concatMapStrings runCase testCases}

    echo "All gha-path-changes tests passed" > "$out"
  ''
