{ ci-lib, ... }:

{
  test-lib-discover-component-names-stack = {
    expr = ci-lib.discoverComponentNames {
      path = ../stacks/fixtures/services;
      stackName = "services";
      deployments.subdirectory = "config";
    };
    expected = [
      "a"
      "b"
    ];
  };
}
