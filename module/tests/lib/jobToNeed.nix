{ ci-lib, ... }:

{
  test-lib-job-to-need = {
    expr = ci-lib.jobToNeed "job1";

    expected = {
      job = "job1";
      artifacts = false;
      optional = true;
    };
  };
}
