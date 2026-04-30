{
  pkgs,
  lib,
  config,
}:

let
  mainBash = ../../packages/gha-job-summary/main.bash;

  # Fake gh binary: ignores all arguments and emits pre-formatted TSV rows
  # as if `gh api --jq '.jobs[] | [.name, (.conclusion // .status), .html_url] | @tsv'`
  # had been called against a run with four jobs.
  fakeGh = pkgs.writeShellScript "gh" ''
    printf '%s\t%s\t%s\n' "deploy"     "success"    "https://example.com/jobs/1"
    printf '%s\t%s\t%s\n' "test"       "failure"    "https://example.com/jobs/2"
    printf '%s\t%s\t%s\n' "smoke-test" "skipped"    "https://example.com/jobs/3"
    printf '%s\t%s\t%s\n' "summary"    "success"    "https://example.com/jobs/4"
  '';
in
pkgs.runCommand "test-gha-job-summary"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
    ];
  }
  ''
    set -euo pipefail

    export GITHUB_REPOSITORY="org/repo"
    export GITHUB_RUN_ID="123"
    export SUMMARY_JOB_NAME="summary"
    export GITHUB_STEP_SUMMARY
    GITHUB_STEP_SUMMARY=$(mktemp)

    # Put the fake gh first on PATH so it wins over any real gh.
    tmpbin=$(mktemp -d)
    cp ${fakeGh} "$tmpbin/gh"
    chmod +x "$tmpbin/gh"
    export PATH="$tmpbin:$PATH"

    # Run the raw script with bash (bypasses writeShellApplication's PATH prepending).
    bash ${mainBash}

    summary=$(cat "$GITHUB_STEP_SUMMARY")

    # Must include deploy (success ✅) and test (failure ❌) with links.
    echo "$summary" | grep -q "deploy"              || { echo "FAIL: deploy missing"; exit 1; }
    echo "$summary" | grep -q "test"                || { echo "FAIL: test missing"; exit 1; }
    echo "$summary" | grep -q "https://example.com" || { echo "FAIL: links missing"; exit 1; }
    echo "$summary" | grep -q "✅"                  || { echo "FAIL: success icon missing"; exit 1; }
    echo "$summary" | grep -q "❌"                  || { echo "FAIL: failure icon missing"; exit 1; }

    # Must NOT include the skipped smoke-test or the summary job itself.
    echo "$summary" | grep -q "smoke-test"  && { echo "FAIL: skipped job should be excluded"; exit 1; } || true
    echo "$summary" | grep -qE "\[summary\]" && { echo "FAIL: summary job should exclude itself"; exit 1; } || true

    echo "All gha-job-summary tests passed" > "$out"
  ''
