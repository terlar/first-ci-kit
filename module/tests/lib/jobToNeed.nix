{ ci-lib, ... }:

{
  test-lib-jobToNeed = {
    expr = ci-lib.jobToNeed "job1";

    expected = {
      job = "job1";
      artifacts = false;
      optional = true;
    };
  };
}
