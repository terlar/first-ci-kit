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
in
{
  inherit
    checkStep
    resolveInputs
    instantiate
    usedBlocks
    ;
}
