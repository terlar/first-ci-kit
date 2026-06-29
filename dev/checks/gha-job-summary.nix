{ pkgs }:

let
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
      pkgs.bats
      pkgs.bash
      pkgs.coreutils
      pkgs.gawk
    ];
  }
  ''
    export fakeCurl=${fakeCurl}
    export fakeCurlAllSkipped=${fakeCurlAllSkipped}
    export fakeCurlNoJobs=${fakeCurlNoJobs}
    export mainBash=${../../packages/gha-job-summary/main.bash}

    bats ${../../packages/gha-job-summary/tests.bats}
    touch "$out"
  ''
