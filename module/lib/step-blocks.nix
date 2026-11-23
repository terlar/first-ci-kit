{ lib }:

let
  checkStep =
    step:
    if step.run != null && step.block != null then
      throw "step: set exactly one of run or block, or only backend-specific fields"
    else if step.inputs != { } && step.block == null then
      throw "step: inputs are only valid with block"
    else if
      step.run == null && step.block == null && step.github-actions == null && step.gitlab-ci == null
    then
      throw "step: set exactly one of run or block, or only backend-specific fields"
    else
      step;

  resolveInputs =
    {
      blocks,
      name,
      inputs,
    }:
    let
      block = blocks.${name} or (throw "stepBlocks.${name}: unknown block");
      unknown = lib.filter (i: !(block.inputs ? ${i})) (builtins.attrNames inputs);
    in
    if unknown != [ ] then
      throw "stepBlocks.${name}: unknown input ${builtins.head unknown}"
    else
      lib.mapAttrs (
        n: spec:
        inputs.${n} or (
          if spec.default != null then
            spec.default
          else
            throw "stepBlocks.${name}: missing required input ${n}"
        )
      ) block.inputs;

  # step -> listOf step, expanding `block` recursively. `stack` is the chain
  # of block names currently being expanded, used to detect cycles.
  instantiate =
    {
      blocks,
      stack ? [ ],
    }:
    step:
    let
      checked = checkStep step;
    in
    if checked.block == null then
      [ checked ]
    else
      let
        name = checked.block;
      in
      if builtins.elem name stack then
        throw "stepBlocks: cycle ${lib.concatStringsSep " -> " (stack ++ [ name ])}"
      else
        let
          block = blocks.${name} or (throw "stepBlocks.${name}: unknown block");
          resolvedInputs = resolveInputs {
            inherit blocks name;
            inherit (checked) inputs;
          };
          nestedSteps = block.steps { inputs = resolvedInputs; };
        in
        lib.concatMap (instantiate {
          inherit blocks;
          stack = stack ++ [ name ];
        }) nestedSteps;

  # Transitive block names referenced by `steps`, used only to decide which
  # blocks are reachable (input values here are placeholders, not validated).
  usedBlocksImpl =
    blocks: stack: steps:
    lib.concatMap (
      step:
      if step.block == null then
        [ ]
      else
        let
          name = step.block;
        in
        if builtins.elem name stack then
          throw "stepBlocks: cycle ${lib.concatStringsSep " -> " (stack ++ [ name ])}"
        else
          let
            block = blocks.${name} or (throw "stepBlocks.${name}: unknown block");
            placeholderInputs = lib.mapAttrs (
              _: spec: if spec.default != null then spec.default else ""
            ) block.inputs;
            nested = block.steps { inputs = placeholderInputs; };
          in
          [ name ] ++ usedBlocksImpl blocks (stack ++ [ name ]) nested
    ) steps;

  usedBlocks =
    { blocks }:
    steps:
    lib.pipe (usedBlocksImpl blocks [ ] steps) [
      lib.unique
      (lib.sort (a: b: a < b))
    ];

  # Render a single run step's attrs, used both for top-level run steps and
  # for the leaves left after expanding a block step.
  renderRunStep =
    step:
    lib.mergeAttrsList [
      { inherit (step) run; }
      (lib.optionalAttrs (step.name != null) { inherit (step) name; })
      (lib.optionalAttrs (step.env != { }) { inherit (step) env; })
      (if step.github-actions != null then step.github-actions else { })
    ];

  # step (already checked) -> listOf attrs, for a non-block step.
  renderNonBlockStep =
    step:
    if step.run != null then
      [ (renderRunStep step) ]
    else if step.github-actions != null then
      [ step.github-actions ]
    else
      # Raw-only gitlab-ci step: dropped on GitHub Actions.
      [ ];

  # { blocks, native } -> listOf step -> listOf attrs
  toGithubSteps =
    { blocks, native }:
    let
      renderStep =
        step:
        let
          checked = checkStep step;
        in
        if checked.block == null then
          renderNonBlockStep checked
        else if native then
          let
            # Validate the block/inputs (unknown block, unknown input names);
            # defaults are not emitted, only the caller-supplied inputs are.
            validated = resolveInputs {
              inherit blocks;
              name = checked.block;
              inherit (checked) inputs;
            };
          in
          builtins.seq validated [
            (lib.mergeAttrsList [
              { uses = "./.github/actions/${checked.block}"; }
              (lib.optionalAttrs (checked.inputs != { }) { "with" = checked.inputs; })
              (lib.optionalAttrs (checked.name != null) { inherit (checked) name; })
              (lib.optionalAttrs (checked.env != { }) { inherit (checked) env; })
              (if checked.github-actions != null then checked.github-actions else { })
            ])
          ]
        else if checked.github-actions != null then
          throw "step: github-actions overrides on a block step need native mode"
        else
          let
            leaves = instantiate { inherit blocks; } checked;
          in
          lib.concatMap (leaf: renderNonBlockStep (leaf // { env = checked.env // leaf.env; })) leaves;
    in
    lib.concatMap renderStep;
in
{
  inherit
    checkStep
    resolveInputs
    instantiate
    usedBlocks
    toGithubSteps
    ;
}
