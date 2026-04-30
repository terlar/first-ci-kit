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

  # Fake curl that returns all-skipped jobs (simulates a no-op pipeline run).
  fakeCurlAllSkipped = pkgs.writeShellScript "curl-all-skipped" ''
    cat <<'EOF'
    {
      "total_count": 2,
      "jobs": [
        {
          "html_url": "https://github.com/org/repo/actions/runs/123/job/1",
          "status": "completed",
          "conclusion": "skipped",
          "name": "deploy",
          "steps": []
        },
        {
          "html_url": "https://github.com/org/repo/actions/runs/123/job/2",
          "status": "completed",
          "conclusion": "success",
          "name": "summary",
          "steps": []
        }
      ]
    }
    EOF
  '';

  # Fake curl that returns an empty job list (simulates a pipeline with no jobs).
  fakeCurlNoJobs = pkgs.writeShellScript "curl-no-jobs" ''
    cat <<'EOF'
    {
      "total_count": 0,
      "jobs": []
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

    run_script() {
      local fake_curl=$1
      local tmpbin
      tmpbin=$(mktemp -d)
      cp "$fake_curl" "$tmpbin/curl"
      chmod +x "$tmpbin/curl"
      export GITHUB_STEP_SUMMARY
      GITHUB_STEP_SUMMARY=$(mktemp)
      PATH="$tmpbin:$PATH" bash --noprofile --norc -e -o pipefail ${mainBash}
    }

    # ── Test 1: normal run ────────────────────────────────────────────────────
    echo "=== Test: normal run ==="
    run_script ${fakeCurl}
    summary=$(cat "$GITHUB_STEP_SUMMARY")

    echo "$summary" | grep -q "deploy"                        || { echo "FAIL: deploy missing"; exit 1; }
    echo "$summary" | grep -q "test"                          || { echo "FAIL: test missing"; exit 1; }
    echo "$summary" | grep -q "https://github.com/org/repo"   || { echo "FAIL: links missing"; exit 1; }
    echo "$summary" | grep -q "✅"                            || { echo "FAIL: success icon missing"; exit 1; }
    echo "$summary" | grep -q "❌"                            || { echo "FAIL: failure icon missing"; exit 1; }
    echo "$summary" | grep -q "smoke-test"   && { echo "FAIL: skipped job should be excluded"; exit 1; } || true
    echo "$summary" | grep -qE "\[summary\]" && { echo "FAIL: summary job should exclude itself"; exit 1; } || true
    echo "PASS"

    # ── Test 2: all-skipped run (broken pipe must not cause failure) ──────────
    echo "=== Test: all-skipped run ==="
    run_script ${fakeCurlAllSkipped}
    echo "PASS (exit 0 with no displayable jobs)"

    # ── Test 3: no-jobs run ───────────────────────────────────────────────────
    echo "=== Test: no-jobs run ==="
    run_script ${fakeCurlNoJobs}
    echo "PASS (exit 0 with empty job list)"

    echo "All gha-job-summary tests passed" > "$out"
  ''
