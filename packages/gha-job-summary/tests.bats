setup() {
  export GITHUB_REPOSITORY="org/repo"
  export GITHUB_RUN_ID="123"
  export GITHUB_API_URL="https://api.github.com"
  export GH_TOKEN="fake-token"
  export SUMMARY_JOB_NAME="summary"
}

run_script() {
  local fake_curl=$1
  local tmpbin
  tmpbin=$(mktemp -d)
  cp "$fake_curl" "$tmpbin/curl"
  chmod +x "$tmpbin/curl"
  GITHUB_STEP_SUMMARY=$(mktemp)
  export GITHUB_STEP_SUMMARY
  PATH="$tmpbin:$PATH" bash --noprofile --norc -e -o pipefail "$mainBash"
}

@test "normal run: deploy success, test failure, skipped excluded, self excluded" {
  run_script "$fakeCurl"
  summary=$(cat "$GITHUB_STEP_SUMMARY")
  [[ "$summary" == *"deploy"* ]]
  [[ "$summary" == *"test"* ]]
  [[ "$summary" == *"https://github.com/org/repo"* ]]
  [[ "$summary" == *"✅"* ]]
  [[ "$summary" == *"❌"* ]]
  [[ "$summary" != *"smoke-test"* ]]
  [[ "$summary" != *'[summary]'* ]]
}

@test "all-skipped run: exits cleanly with no displayable jobs" {
  run_script "$fakeCurlAllSkipped"
}

@test "no-jobs run: exits cleanly with empty job list" {
  run_script "$fakeCurlNoJobs"
}
