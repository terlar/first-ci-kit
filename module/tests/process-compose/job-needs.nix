{ test-lib, ... }:

{
  test-process-compose-job-with-needs = {
    expr = test-lib.eval-process-compose {
      jobs.job-a = { };
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };
    expected = {
      processes.job-a = { };
      processes.job-b.depends_on.job-a.condition = "process_completed_successfully";
    };
  };

  # Optional needs use process_completed so the job still runs even if
  # the optional dependency did not succeed.
  test-process-compose-job-with-optional-need = {
    expr = test-lib.eval-process-compose {
      jobs.job-a = { };
      jobs.job-b.needs = [
        {
          job = "job-a";
          optional = true;
        }
      ];
    };
    expected = {
      processes.job-a = { };
      processes.job-b.depends_on.job-a.condition = "process_completed";
    };
  };

  # runAlways = true causes all dependency conditions to use process_completed
  # so the job runs even when a required dependency failed.
  test-process-compose-job-run-always = {
    expr = test-lib.eval-process-compose {
      jobs.job-a = { };
      jobs.job-b = {
        runAlways = true;
        needs = [ { job = "job-a"; } ];
      };
    };
    expected = {
      processes.job-a = { };
      processes.job-b.depends_on.job-a.condition = "process_completed";
    };
  };

  # Disabled jobs are excluded from depends_on.
  test-process-compose-job-disabled-need = {
    expr = test-lib.eval-process-compose {
      jobs.job-a.enable = false;
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };
    expected = {
      processes.job-b = { };
    };
  };

  # process-compose.enable = false excludes the job from the backend and
  # also removes it from any other job's depends_on.
  test-process-compose-job-backend-disabled-need = {
    expr = test-lib.eval-process-compose {
      jobs.job-a.process-compose.enable = false;
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };
    expected = {
      processes.job-b = { };
    };
  };
}
