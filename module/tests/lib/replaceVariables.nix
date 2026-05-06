{ ci-lib, ... }:

{
  test-lib-replace-variables = {
    expr = ci-lib.replaceVariables {
      var1 = "Var 1 Value";
    } [ "This is {var1}" ];

    expected = [ "This is Var 1 Value" ];
  };
}
