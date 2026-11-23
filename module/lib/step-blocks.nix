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
      # Set by the expanded GitHub renderer: a `github-actions` override on
      # any block step along the expansion (not only the top-level one)
      # needs native mode, same as the top-level check.
      forbidGithubActions ? false,
    }:
    step:
    let
      checked = checkStep step;
    in
    if checked.block == null then
      [ checked ]
    else if forbidGithubActions && checked.github-actions != null then
      throw "step: github-actions overrides on a block step need native mode"
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
          inherit blocks forbidGithubActions;
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
          builtins.deepSeq validated [
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
            leaves = instantiate {
              inherit blocks;
              forbidGithubActions = true;
            } checked;
          in
          lib.concatMap (leaf: renderNonBlockStep (leaf // { env = checked.env // leaf.env; })) leaves;
    in
    lib.concatMap renderStep;

  # Render a step's own run/raw lines, ignoring env/name (applied by the caller).
  renderShellLeaf =
    step:
    if step.run != null then
      [ step.run ]
    else if step.gitlab-ci != null then
      step.gitlab-ci
    else
      # Raw-only github-actions step: dropped on neutral shell backends.
      [ ];

  # Wrap a step's rendered body lines with its own env (one collapsed shell
  # group) and then its name (start/end lines around the result).
  wrapShellStep =
    { nameLines }:
    {
      step,
      lines,
      id,
    }:
    let
      withEnv =
        if step.env != { } then
          let
            # `$VAR` is intentionally left to expand, like GitHub's `${{ }}`.
            exports = lib.concatStringsSep " " (
              map (k: ''${k}="${lib.escape [ "\\" "\"" "`" ] step.env.${k}}"'') (builtins.attrNames step.env)
            );
          in
          [ "( export ${exports}\n${lib.concatStringsSep "\n" lines}\n)" ]
        else
          lines;
    in
    if step.name != null then
      let
        nl = nameLines id step.name;
      in
      (lib.optional (nl.start != "") nl.start) ++ withEnv ++ (lib.optional (nl.end != "") nl.end)
    else
      withEnv;

  # { blocks, nameLines } -> listOf step -> listOf str
  # Does not reuse `instantiate`: it needs a per-step path (not just the
  # flattened leaves) to derive stable section ids for nested blocks.
  toShellLines =
    { blocks, nameLines }:
    let
      wrap = wrapShellStep { inherit nameLines; };

      renderStep =
        stack: path: step:
        let
          checked = checkStep step;
          id = "step_${lib.concatStringsSep "_" (map toString path)}";
        in
        if checked.block == null then
          wrap {
            step = checked;
            lines = renderShellLeaf checked;
            inherit id;
          }
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
              nestedSteps = builtins.deepSeq resolvedInputs (block.steps { inputs = resolvedInputs; });
              bodyLines = lib.concatLists (
                lib.imap0 (j: s: renderStep (stack ++ [ name ]) (path ++ [ j ]) s) nestedSteps
              );
            in
            wrap {
              step = checked;
              lines = bodyLines;
              inherit id;
            };
    in
    steps: lib.concatLists (lib.imap0 (i: step: renderStep [ ] [ i ] step) steps);

  # { blocks } -> name -> attrs, a composite action.yml for one block.
  toGithubAction =
    { blocks }:
    name:
    let
      block = blocks.${name} or (throw "stepBlocks.${name}: unknown block");
      placeholderInputs = lib.mapAttrs (n: _: "\${{ inputs.${n} }}") block.inputs;
      # Composite action `run` steps require an explicit shell.
      steps = map (step: if step ? run && !(step ? shell) then step // { shell = "bash"; } else step) (
        toGithubSteps {
          inherit blocks;
          native = true;
        } (block.steps { inputs = placeholderInputs; })
      );
    in
    lib.mergeAttrsList [
      { inherit name; }
      (lib.optionalAttrs (block.description != "") { inherit (block) description; })
      {
        inputs = lib.mapAttrs (
          _: spec:
          lib.mergeAttrsList [
            { required = spec.default == null; }
            (lib.optionalAttrs (spec.default != null) { inherit (spec) default; })
            (lib.optionalAttrs (spec.description != "") { inherit (spec) description; })
          ]
        ) block.inputs;
        runs = {
          using = "composite";
          inherit steps;
        };
      }
    ];
in
{
  inherit
    checkStep
    resolveInputs
    instantiate
    usedBlocks
    toGithubSteps
    toShellLines
    toGithubAction
    ;
}
