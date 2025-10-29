{ ci-lib, ... }:

{
  test-lib-documentsToYAML-multiple-documents = {
    expr = ci-lib.documentsToYAML [
      { document1 = "one"; }
      { document2 = "two"; }
    ];

    expected = ''
      {"document1":"one"}
      ---
      {"document2":"two"}
    '';
  };

  test-lib-documentsToYAML-single-document = {
    expr = ci-lib.documentsToYAML [
      { document1 = "one"; }
    ];

    expected = ''
      {"document1":"one"}
    '';
  };
}
