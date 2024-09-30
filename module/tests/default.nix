{ lib, pkgs, ... }:

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
          specialArgs = {
            inherit pkgs;
          };
        };
      in
      eval.config;

    eval-gitlab-ci = modules: (evalConfig modules).pipeline.gitlab-ci.settings;

    pathRulesMR =
      paths:
      [
        {
          "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
          changes = {
            inherit paths;
            compare_to = "refs/heads/$CI_DEFAULT_BRANCH";
          };
        }
      ]
      ++ pathRulesMain paths;

    pathRulesMain = paths: [
      {
        "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
        changes = {
          inherit paths;
        };
      }
    ];
  };

  tests = lib.pipe ./. [
    lib.filesystem.listFilesRecursive
    (builtins.filter (path: path != ./default.nix))
    (map (path: import path { inherit lib test-lib; }))
    lib.mergeAttrsList
  ];
in
test-lib.assertRunTests tests
