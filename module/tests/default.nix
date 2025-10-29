{ lib, ci-lib, ... }:

let
  test-lib = rec {
    assertRunTests =
      tests:
      lib.pipe tests [
        lib.runTests
        (map (
          test@{
            name,
            expected,
            result,
          }:
          if builtins.isAttrs expected && builtins.isAttrs result then
            {
              inherit name;
              expected = filterDivergedAttrsRecursive expected result;
              result = filterDivergedAttrsRecursive result expected;
            }
          else
            test
        ))
        (lib.generators.toPretty { })
        (res: lib.assertMsg (res == "[ ]") res)
      ];

    filterDivergedAttrsRecursive =
      lhs: rhs:
      let
        pred = path: v: (!lib.hasAttrByPath path rhs || (lib.getAttrFromPath path rhs) != v);
        recurse =
          path: set:
          lib.listToAttrs (
            lib.concatMap (
              name:
              let
                v = set.${name};
                p = path ++ [ name ];
              in
              if pred p v then [ (lib.nameValuePair name (if lib.isAttrs v then recurse p v else v)) ] else [ ]
            ) (lib.attrNames set)
          );
      in
      recurse [ ] lhs;

    evalConfig =
      modules:
      let
        eval = lib.evalModules {
          modules = [ ./.. ] ++ (lib.toList modules);
        };
      in
      eval.config;

    eval-github-actions = modules: (evalConfig modules).pipeline.github-actions.settings;

    eval-gitlab-ci = modules: (evalConfig modules).pipeline.gitlab-ci.settings;
    eval-gitlab-ci-documents = modules: (evalConfig modules).pipeline.gitlab-ci.fileDocuments;
  };

  tests = lib.pipe ./. [
    lib.filesystem.listFilesRecursive
    (builtins.filter (path: path != ./default.nix))
    (map (path: import path { inherit lib ci-lib test-lib; }))
    lib.mergeAttrsList
  ];
in
test-lib.assertRunTests tests
