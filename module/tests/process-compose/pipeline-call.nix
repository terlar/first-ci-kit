{ test-lib, ... }:

let
  sentinelCommand = pipeline: ''echo "Pipeline ${pipeline} complete"'';
in
{
  # Child pipeline jobs are inlined as "${parentJobName}_${childJobName}",
  # and a sentinel process "${parentJobName}" is created that depends_on all
  # inlined child processes.
  test-process-compose-pipeline-call-basic = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs = {
        plan.commands = [ "terraform plan" ];
        apply.commands = [ "terraform apply" ];
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      processes = {
        deploy_plan.command = "terraform plan";
        deploy_apply.command = "terraform apply";
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on = {
            deploy_plan.condition = "process_completed_successfully";
            deploy_apply.condition = "process_completed_successfully";
          };
        };
      };
    };
  };

  # The sentinel process for the pipelineCall job uses the descriptive echo command.
  test-process-compose-pipeline-call-sentinel-command = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs.plan.commands = [ "terraform plan" ];
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      processes = {
        deploy_plan.command = "terraform plan";
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on.deploy_plan.condition = "process_completed_successfully";
        };
      };
    };
  };

  # The sentinel depends_on all inlined child processes.
  test-process-compose-pipeline-call-sentinel-depends-on = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs = {
        plan.commands = [ "terraform plan" ];
        apply.commands = [ "terraform apply" ];
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      processes = {
        deploy_plan.command = "terraform plan";
        deploy_apply.command = "terraform apply";
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on = {
            deploy_plan.condition = "process_completed_successfully";
            deploy_apply.condition = "process_completed_successfully";
          };
        };
      };
    };
  };

  # Internal child depends_on (plan → apply) are remapped to namespaced names.
  test-process-compose-pipeline-call-child-internal-needs-remapped = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs = {
        plan.commands = [ "terraform plan" ];
        apply = {
          commands = [ "terraform apply" ];
          needs = [ { job = "plan"; } ];
        };
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      processes = {
        deploy_plan.command = "terraform plan";
        deploy_apply = {
          command = "terraform apply";
          depends_on.deploy_plan.condition = "process_completed_successfully";
        };
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on = {
            deploy_plan.condition = "process_completed_successfully";
            deploy_apply.condition = "process_completed_successfully";
          };
        };
      };
    };
  };

  # Root child jobs (no depends_on of their own) inherit the parent job's needs.
  # deploy_plan is a root child job so it gets validate as a dependency.
  test-process-compose-pipeline-call-parent-needs-propagated = {
    expr = test-lib.eval-process-compose {
      jobs.validate.commands = [ "make validate" ];
      pipelines.my-pipeline.jobs.plan.commands = [ "terraform plan" ];
      jobs.deploy = {
        needs = [ { job = "validate"; } ];
        pipelineCall.pipeline = "my-pipeline";
      };
    };
    expected = {
      processes = {
        validate.command = "make validate";
        deploy_plan = {
          command = "terraform plan";
          depends_on.validate.condition = "process_completed_successfully";
        };
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on.deploy_plan.condition = "process_completed_successfully";
        };
      };
    };
  };

  # Non-root child jobs do NOT get the parent's needs injected. deploy_apply
  # depends on deploy_plan (internal child dep) but NOT on validate (parent dep),
  # since deploy_plan already guards the parent prerequisite.
  test-process-compose-pipeline-call-non-root-child-no-parent-needs = {
    expr = test-lib.eval-process-compose {
      jobs.validate.commands = [ "make validate" ];
      pipelines.my-pipeline.jobs = {
        plan.commands = [ "terraform plan" ];
        apply = {
          commands = [ "terraform apply" ];
          needs = [ { job = "plan"; } ];
        };
      };
      jobs.deploy = {
        needs = [ { job = "validate"; } ];
        pipelineCall.pipeline = "my-pipeline";
      };
    };
    expected = {
      processes = {
        validate.command = "make validate";
        deploy_plan = {
          command = "terraform plan";
          # Root child job: inherits parent's needs.
          depends_on.validate.condition = "process_completed_successfully";
        };
        deploy_apply = {
          command = "terraform apply";
          # Non-root child job: only depends on its child-internal dep, not validate.
          depends_on.deploy_plan.condition = "process_completed_successfully";
        };
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on = {
            deploy_plan.condition = "process_completed_successfully";
            deploy_apply.condition = "process_completed_successfully";
          };
        };
      };
    };
  };

  # runAlways = true: sentinel uses process_completed for all child processes.
  test-process-compose-pipeline-call-run-always-sentinel-condition = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs.plan.commands = [ "terraform plan" ];
      jobs.deploy = {
        runAlways = true;
        pipelineCall.pipeline = "my-pipeline";
      };
    };
    expected = {
      processes = {
        deploy_plan.command = "terraform plan";
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on.deploy_plan.condition = "process_completed";
        };
      };
    };
  };

  # runAlways = true: parent's needs are also propagated with process_completed.
  test-process-compose-pipeline-call-run-always-parent-needs-condition = {
    expr = test-lib.eval-process-compose {
      jobs.validate.commands = [ "make validate" ];
      pipelines.my-pipeline.jobs.plan.commands = [ "terraform plan" ];
      jobs.deploy = {
        runAlways = true;
        needs = [ { job = "validate"; } ];
        pipelineCall.pipeline = "my-pipeline";
      };
    };
    expected = {
      processes = {
        validate.command = "make validate";
        deploy_plan = {
          command = "terraform plan";
          depends_on.validate.condition = "process_completed";
        };
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on.deploy_plan.condition = "process_completed";
        };
      };
    };
  };

  # process-compose.enable = false on the pipelineCall job: nothing is inlined.
  test-process-compose-pipeline-call-disabled = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs.plan.commands = [ "terraform plan" ];
      jobs.deploy = {
        process-compose.enable = false;
        pipelineCall.pipeline = "my-pipeline";
      };
    };
    expected = {
      processes = { };
    };
  };

  # Child pipeline with no process-compose-enabled jobs: sentinel has no depends_on.
  test-process-compose-pipeline-call-empty-child = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs.plan = {
        commands = [ "terraform plan" ];
        process-compose.enable = false;
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      processes.deploy.command = sentinelCommand "my-pipeline";
    };
  };

  # A parent job that needs a pipelineCall job depends_on the sentinel.
  test-process-compose-pipeline-call-parent-depends-on-sentinel = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs.plan.commands = [ "terraform plan" ];
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
      jobs.notify = {
        commands = [ "notify.sh" ];
        needs = [ { job = "deploy"; } ];
      };
    };
    expected = {
      processes = {
        deploy_plan.command = "terraform plan";
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on.deploy_plan.condition = "process_completed_successfully";
        };
        notify = {
          command = "notify.sh";
          depends_on.deploy.condition = "process_completed_successfully";
        };
      };
    };
  };

  # A pipelineCall job in the child pipeline is skipped (with a warning) and
  # only the non-pipelineCall child job is inlined.
  test-process-compose-pipeline-call-nested-pipelinecall-skipped = {
    expr = test-lib.eval-process-compose {
      pipelines.inner.jobs.build.commands = [ "make build" ];
      pipelines.outer.jobs = {
        build.commands = [ "make build" ];
        trigger.pipelineCall.pipeline = "inner";
      };
      jobs.run.pipelineCall.pipeline = "outer";
    };
    expected = {
      processes = {
        # trigger (pipelineCall in outer) is skipped; only outer's build is inlined.
        run_build.command = "make build";
        run = {
          command = sentinelCommand "outer";
          depends_on.run_build.condition = "process_completed_successfully";
        };
      };
    };
  };

  # pipelineCall inputs are injected as uppercased environment variables into
  # inlined child processes so that commands like $STACK/$COMPONENT/$DEPLOYMENT
  # are resolved at runtime.
  test-process-compose-pipeline-call-inputs-injected-as-env = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs.plan.commands = [ "tofu -chdir=terraform/$STACK/$COMPONENT plan" ];
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs = {
          stack = "cluster";
          component = "control-plane";
          deployment = "dev";
        };
      };
    };
    expected = {
      processes = {
        deploy_plan = {
          command = "tofu -chdir=terraform/$STACK/$COMPONENT plan";
          environment = [
            "COMPONENT=control-plane"
            "DEPLOYMENT=dev"
            "STACK=cluster"
          ];
        };
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on.deploy_plan.condition = "process_completed_successfully";
        };
      };
    };
  };

  # Raw child pipeline jobs (plan, apply) must NOT leak into the parent
  # pipeline's process-compose output; only the namespaced inlined versions
  # (deploy_plan, deploy_apply) and the sentinel (deploy) should appear.
  test-process-compose-pipeline-call-raw-jobs-not-leaked = {
    expr = test-lib.eval-process-compose {
      pipelines.my-pipeline.jobs = {
        plan.commands = [ "tofu plan" ];
        apply.commands = [ "tofu apply" ];
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      processes = {
        deploy_plan.command = "tofu plan";
        deploy_apply.command = "tofu apply";
        deploy = {
          command = sentinelCommand "my-pipeline";
          depends_on = {
            deploy_plan.condition = "process_completed_successfully";
            deploy_apply.condition = "process_completed_successfully";
          };
        };
      };
    };
  };
}
