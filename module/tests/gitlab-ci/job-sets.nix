{ test-lib, ... }:

{
  test-job-set-with-needs = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        set1-job1 = { };
        set1-job2 = { };
        set2-job1 = { };
        set2-job2 = { };
      };
      jobSets = {
        set1.jobs = [
          "set1-job1"
          "set1-job2"
        ];
        set2 = {
          needs = [ { jobSet = "set1"; } ];
          jobs = [
            "set2-job1"
            "set2-job2"
          ];
        };
      };
    };

    expected =
      let
        needs = [
          {
            artifacts = false;
            job = "set1-job1";
            optional = true;
          }
          {
            artifacts = false;
            job = "set1-job2";
            optional = true;
          }
        ];
      in
      {
        set1-job1 = { };
        set1-job2 = { };
        set2-job1 = {
          inherit needs;
        };
        set2-job2 = {
          inherit needs;
        };
      };
  };

  test-job-set-with-jobDefaults = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        set1-job1 = { };
        set1-job2 = { };
        set2-job1 = { };
        set2-job2 = { };
      };
      jobSets = {
        set1 = {
          jobDefaults.image = "default-image";
          jobs = [
            "set1-job1"
            "set1-job2"
          ];
        };
        set2.jobs = [
          "set2-job1"
          "set2-job2"
        ];
      };
    };

    expected = {
      set1-job1 = {
        image = "default-image";
      };
      set1-job2 = {
        image = "default-image";
      };
      set2-job1 = { };
      set2-job2 = { };
    };
  };

  test-job-set-with-multiple-jobDefaults = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        job1 = { };
        job2 = { };
      };
      jobSets = {
        set1 = {
          jobDefaults.commands = [ "set1 command" ];
          jobs = [
            "job1"
            "job2"
          ];
        };
        set2 = {
          jobDefaults.commands = [ "set2 command" ];
          jobs = [
            "job1"
            "job2"
          ];
        };
      };
    };

    expected = {
      job1.script = [
        "set1 command"
        "set2 command"
      ];
      job2.script = [
        "set1 command"
        "set2 command"
      ];
    };
  };

  test-job-set-with-tags = {
    expr = test-lib.eval-gitlab-ci {
      jobs = {
        set1-job1 = {
          tags = [ "set1" ];
        };
        set1-job2 = {
          tags = [ "set1" ];
        };
        set2-job1 = {
          tags = [ "set2" ];
        };
        set2-job2 = {
          tags = [ "set2" ];
        };
      };
      jobSets = {
        set1 = {
          jobDefaults.image = "default-image";
          tags = [ "set1" ];
        };
        set2.tags = [ "set2" ];
      };
    };

    expected = {
      set1-job1 = {
        image = "default-image";
      };
      set1-job2 = {
        image = "default-image";
      };
      set2-job1 = { };
      set2-job2 = { };
    };
  };
}
