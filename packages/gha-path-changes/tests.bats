setup() {
  GITHUB_OUTPUT=$(mktemp)
  GITHUB_STEP_SUMMARY=$(mktemp)
  export GITHUB_OUTPUT GITHUB_STEP_SUMMARY
}

@test "push: svc-a changed" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$HEAD_SHA"
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true,"svc-b":false}' ]
}

@test "pull_request: svc-a changed" {
  export GITHUB_EVENT_NAME=pull_request GITHUB_BASE_REF=main GITHUB_HEAD_REF=feature
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true,"svc-b":false}' ]
}

@test "push: no service changed" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$HEAD_SHA" GITHUB_EVENT_AFTER="$NEW_HEAD"
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":false,"svc-b":false}' ]
}

@test "push: colon in group name, svc-a changed" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$HEAD_SHA"
  export DIFF_PATHS=$'org:svc-a:services/svc-a/**\norg:svc-b:services/svc-b/**'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"org:svc-a":true,"org:svc-b":false}' ]
}

@test "push: **/* matches single-level file under module" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$MODULE_SHALLOW_SHA"
  export DIFF_PATHS=$'svc-a:services/svc-a/module/**/*\nsvc-b:services/svc-b/module/**/*'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true,"svc-b":false}' ]
}

@test "push: **/* matches deeply nested file under module (1 subdir)" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$MODULE_DEEP_SHA"
  export DIFF_PATHS=$'svc-a:services/svc-a/module/**/*\nsvc-b:services/svc-b/module/**/*'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true,"svc-b":false}' ]
}

@test "push: **/* matches deeply nested file under module (2 subdirs)" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$MODULE_VERY_DEEP_SHA"
  export DIFF_PATHS=$'svc-a:services/svc-a/module/**/*\nsvc-b:services/svc-b/module/**/*'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true,"svc-b":false}' ]
}

@test "push: * does not match across directory boundary" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$MODULE_SHALLOW_SHA" GITHUB_EVENT_AFTER="$MODULE_DEEP_SHA"
  export DIFF_PATHS=$'svc-a:services/svc-a/module/*\nsvc-b:services/svc-b/module/*'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":false,"svc-b":false}' ]
}

@test "push: alternation matches via second pattern" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$MODULE_SHALLOW_SHA"
  export DIFF_PATHS='svc-a:services/svc-a/config/*|services/svc-a/module/**/*'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true}' ]
}

@test "push: exact path matches specific file" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$TAG_SHA"
  export DIFF_PATHS='svc-a:services/svc-a/module/tag'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true}' ]
}

@test "push: exact path does not match other files" {
  export GITHUB_EVENT_NAME=push GITHUB_EVENT_BEFORE="$BASE_SHA" GITHUB_EVENT_AFTER="$MODULE_SHALLOW_SHA"
  export DIFF_PATHS='svc-a:services/svc-a/module/tag'
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":false}' ]
}

@test "workflow_dispatch: all jobs run when force_run_all=true" {
  export GITHUB_EVENT_NAME=workflow_dispatch FORCE_RUN_ALL=true
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":true,"svc-b":true}' ]
}

@test "workflow_dispatch: all jobs skipped when force_run_all not set" {
  export GITHUB_EVENT_NAME=workflow_dispatch
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":false,"svc-b":false}' ]
}

@test "workflow_dispatch: all jobs skipped when force_run_all=false" {
  export GITHUB_EVENT_NAME=workflow_dispatch FORCE_RUN_ALL=false
  (cd "$repo"; gha-path-changes) >/dev/null
  run grep '^changes=' "$GITHUB_OUTPUT"
  [ "$output" = 'changes={"svc-a":false,"svc-b":false}' ]
}
