{
  pkgs,
  config,
}:

let
  ghaPathChanges = config.packages.gha-path-changes;
in
pkgs.runCommand "test-gha-path-changes"
  {
    nativeBuildInputs = [
      pkgs.git
      ghaPathChanges
      pkgs.bats
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

    export repo BASE_SHA HEAD_SHA NEW_HEAD MODULE_SHALLOW_SHA MODULE_DEEP_SHA MODULE_VERY_DEEP_SHA TAG_SHA

    bats ${../../packages/gha-path-changes/tests.bats}
    touch "$out"
  ''
