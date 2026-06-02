{ test-lib, ... }:

{
  # before_script is prepended to the main commands.
  test-process-compose-before-script-prepended = {
    expr = test-lib.eval-process-compose {
      jobs.job1 = {
        process-compose.before_script = [ "source env.sh" ];
        commands = [ "make test" ];
      };
    };
    expected = {
      processes.job1.command = "source env.sh\nmake test";
    };
  };

  # before_script without commands still produces a command.
  test-process-compose-before-script-without-commands = {
    expr = test-lib.eval-process-compose {
      jobs.job1.process-compose.before_script = [
        "source env.sh"
        "export FOO=bar"
      ];
    };
    expected = {
      processes.job1.command = "source env.sh\nexport FOO=bar";
    };
  };

  # before_script is not present in the generated process config.
  test-process-compose-before-script-stripped-from-output = {
    expr = test-lib.eval-process-compose {
      jobs.job1 = {
        process-compose.before_script = [ "source env.sh" ];
        commands = [ "make test" ];
      };
    };
    expected = {
      # before_script must not appear as a field in the process config.
      processes.job1 = {
        command = "source env.sh\nmake test";
      };
    };
  };

  # before_script is propagated via jobDefaults and prepended for all jobs in
  # the matching job set.
  test-process-compose-before-script-via-job-defaults = {
    expr = test-lib.eval-process-compose {
      jobSets.setup = {
        tags = [ "setup" ];
        jobDefaults.process-compose.before_script = [ "source env.sh" ];
      };
      jobs.job1 = {
        tags = [ "setup" ];
        commands = [ "make test" ];
      };
    };
    expected = {
      processes.job1.command = "source env.sh\nmake test";
    };
  };

  # before_script is prepended inside inlined pipelineCall child processes too.
  test-process-compose-before-script-pipelinecall-child = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs.plan = {
        process-compose.before_script = [ "source env.sh" ];
        commands = [ "make plan" ];
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      processes = {
        deploy_plan = {
          command = "source env.sh\nmake plan";
        };
        deploy = {
          command = "echo \"Pipeline my-pipeline complete\"";
          depends_on.deploy_plan.condition = "process_completed_successfully";
        };
      };
    };
  };
}
