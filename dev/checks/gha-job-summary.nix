{ pkgs }:

let
  mainBash = ../../packages/gha-job-summary/main.bash;

  # Fake curl binary: ignores all arguments and emits a GitHub API JSON response
  # as if GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs had been called
  # against a run with four jobs (one page, total_count=4).
  fakeCurl = pkgs.writeShellScript "curl" ''
    cat <<'EOF'
    {
      "total_count": 4,
      "jobs": [
        {
          "html_url": "https://github.com/org/repo/actions/runs/123/job/1",
          "status": "completed",
          "conclusion": "success",
          "name": "deploy",
          "steps": []
        },
        {
          "html_url": "https://github.com/org/repo/actions/runs/123/job/2",
          "status": "completed",
          "conclusion": "failure",
          "name": "test",
          "steps": []
        },
        {
          "html_url": "https://github.com/org/repo/actions/runs/123/job/3",
          "status": "completed",
          "conclusion": "skipped",
          "name": "smoke-test",
          "steps": []
        },
        {
          "html_url": "https://github.com/org/repo/actions/runs/123/job/4",
          "status": "completed",
          "conclusion": "success",
          "name": "summary",
          "steps": []
        }
      ]
    }
    EOF
  '';
in
pkgs.runCommand "test-gha-job-summary"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.coreutils
      pkgs.gawk
    ];
  }
  ''
    set -euo pipefail

    export GITHUB_REPOSITORY="org/repo"
    export GITHUB_RUN_ID="123"
    export GITHUB_API_URL="https://api.github.com"
    export GH_TOKEN="fake-token"
    export SUMMARY_JOB_NAME="summary"
    export GITHUB_STEP_SUMMARY
    GITHUB_STEP_SUMMARY=$(mktemp)

    # Put the fake curl first on PATH so it wins over any real curl.
    tmpbin=$(mktemp -d)
    cp ${fakeCurl} "$tmpbin/curl"
    chmod +x "$tmpbin/curl"
    export PATH="$tmpbin:$PATH"

    # Run the raw script with bash (bypasses writeShellApplication's PATH prepending).
    bash ${mainBash}

    summary=$(cat "$GITHUB_STEP_SUMMARY")

    # Must include deploy (success ✅) and test (failure ❌) with links.
    echo "$summary" | grep -q "deploy"                        || { echo "FAIL: deploy missing"; exit 1; }
    echo "$summary" | grep -q "test"                          || { echo "FAIL: test missing"; exit 1; }
    echo "$summary" | grep -q "https://github.com/org/repo"   || { echo "FAIL: links missing"; exit 1; }
    echo "$summary" | grep -q "✅"                            || { echo "FAIL: success icon missing"; exit 1; }
    echo "$summary" | grep -q "❌"                            || { echo "FAIL: failure icon missing"; exit 1; }

    # Must NOT include the skipped smoke-test or the summary job itself.
    echo "$summary" | grep -q "smoke-test"   && { echo "FAIL: skipped job should be excluded"; exit 1; } || true
    echo "$summary" | grep -qE "\[summary\]" && { echo "FAIL: summary job should exclude itself"; exit 1; } || true

    echo "All gha-job-summary tests passed" > "$out"
  ''
