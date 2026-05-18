{ test-lib, ... }:

{
  test-gitlab-ci-job-with-needs = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a = { };
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };

    expected = {
      job-a = { };
      job-b.needs = [
        {
          artifacts = true;
          job = "job-a";
          optional = false;
        }
      ];
    };
  };

  test-gitlab-ci-job-with-external-needs = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a.needs = [ { job = "external-job"; } ];
    };

    expected = {
      job-a.needs = [
        {
          artifacts = true;
          job = "external-job";
          optional = false;
        }
      ];
    };
  };

  test-gitlab-ci-job-with-external-needs-and-transform = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.transformJobName = builtins.replaceStrings [ "_" ] [ ":" ];
      jobs.job_a.needs = [
        { job = "job_b"; }
        { job = "external_job"; }
      ];
      jobs.job_b = { };
    };

    expected = {
      "job:a".needs = [
        {
          artifacts = true;
          job = "job:b";
          optional = false;
        }
        {
          artifacts = true;
          job = "external_job";
          optional = false;
        }
      ];
      "job:b" = { };
    };
  };

  test-gitlab-ci-job-with-self-needs = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a.needs = [ { job = "job-a"; } ];
    };

    expected = {
      job-a = { };
    };
  };

  test-gitlab-ci-job-with-needs-jobset = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a = { };
      jobs.job-b.needs = [ { jobSet = "jobset-a"; } ];

      jobSets.jobset-a.jobs = [ "job-a" ];
    };

    expected = {
      job-a = { };
      job-b.needs = [
        {
          artifacts = true;
          job = "job-a";
          optional = false;
        }
      ];
    };
  };

  # optional = true is passed through to the rendered need.
  test-gitlab-ci-job-with-optional-need = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a = { };
      jobs.job-b.needs = [
        {
          job = "job-a";
          optional = true;
        }
      ];
    };

    expected = {
      job-a = { };
      job-b.needs = [
        {
          artifacts = true;
          job = "job-a";
          optional = true;
        }
      ];
    };
  };

  # runAlways = true sets when: always on the GitLab CI job.
  test-gitlab-ci-job-run-always = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job-a = { };
      jobs.job-b = {
        runAlways = true;
        needs = [ { job = "job-a"; } ];
      };
    };

    expected = {
      job-a = { };
      job-b = {
        needs = [
          {
            artifacts = true;
            job = "job-a";
            optional = false;
          }
        ];
        when = "always";
      };
    };
  };
}
