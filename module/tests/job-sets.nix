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
          needs = [ { jobSet = "set2"; } ];
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
            job = "set2-job1";
            optional = true;
          }
          {
            artifacts = false;
            job = "set2-job2";
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
}
