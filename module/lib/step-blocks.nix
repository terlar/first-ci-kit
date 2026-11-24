{ lib }:

let
  checkStep =
    step:
    let
      hasRun = step.run != null;
      hasBlock = step.block != null;
      hasRaw = step.github-actions != null || step.gitlab-ci != null;
    in
    lib.pipe step [
      (lib.throwIf (hasRun && hasBlock) "step: run and block are mutually exclusive")
      (lib.throwIfNot (hasRun || hasBlock || hasRaw) "step: set run, block, or a backend-specific field")
      (lib.throwIf (step.inputs != { } && !hasBlock) "step: inputs are only valid with block")
    ];

  # Block `name`, entered from the chain of blocks in `stack`; throws on a
  # cycle or an unknown name.
  enterBlock =
    blocks: stack: name:
    let
      chain = lib.concatStringsSep " -> " (stack ++ [ name ]);
    in
    lib.pipe blocks [
      (lib.throwIf (lib.elem name stack) "stepBlocks: cycle ${chain}")
      (lib.throwIfNot (blocks ? ${name}) "stepBlocks.${name}: unknown block")
      (lib.getAttr name)
    ];

  resolveInputs =
    {
      blocks,
      name,
      inputs,
    }:
    let
      block = enterBlock blocks [ ] name;
      names = lib.attrNames block.inputs;
      given = lib.attrNames inputs;
      unknown = lib.subtractLists names given;
      missing = lib.subtractLists given (lib.filter (n: block.inputs.${n}.default == null) names);
    in
    lib.pipe block.inputs [
      (lib.throwIf (unknown != [ ]) "stepBlocks.${name}: unknown input ${toString unknown}")
      (lib.throwIf (missing != [ ]) "stepBlocks.${name}: missing required input ${toString missing}")
      (lib.mapAttrs (n: spec: inputs.${n} or spec.default))
    ];

  # Steps of block step `checked` entered from `stack`, with validated inputs.
  blockSteps =
    blocks: stack: checked:
    let
      block = enterBlock blocks stack checked.block;
      inputs = resolveInputs {
        inherit blocks;
        name = checked.block;
        inherit (checked) inputs;
      };
    in
    builtins.deepSeq inputs (block.steps { inherit inputs; });

  # step -> listOf step, expanding `block` recursively.
  instantiate =
    {
      blocks,
      # Set by the expanded GitHub renderer: a `github-actions` override on
      # any block step along the expansion needs native mode.
      forbidGithubActions ? false,
    }:
    let
      # `stack` is the chain of block names being expanded, for cycle detection.
      recurse =
        stack: step:
        let
          checked = checkStep step;
          name = checked.block;
        in
        if name == null then
          [ checked ]
        else
          lib.throwIf (forbidGithubActions && checked.github-actions != null)
            "step: github-actions overrides on a block step need native mode"
            (lib.concatMap (recurse (stack ++ [ name ])) (blockSteps blocks stack checked));
    in
    recurse [ ];

  # Transitive block names referenced by `steps`, used only to decide which
  # blocks are reachable (input values here are placeholders, not validated).
  usedBlocks =
    { blocks }:
    let
      recurse =
        stack:
        lib.concatMap (
          step:
          let
            name = step.block;
            block = enterBlock blocks stack name;
            placeholderInputs = lib.mapAttrs (_: spec: lib.defaultTo "" spec.default) block.inputs;
            nested = block.steps { inputs = placeholderInputs; };
          in
          if name == null then [ ] else [ name ] ++ recurse (stack ++ [ name ]) nested
        );
    in
    steps:
    lib.pipe steps [
      (recurse [ ])
      lib.unique
      (lib.sort lib.lessThan)
    ];

  # Base attrs plus a step's optional name/env and github-actions override.
  renderStepAttrs =
    base: step:
    lib.mergeAttrsList [
      base
      (lib.optionalAttrs (step.name != null) { inherit (step) name; })
      (lib.optionalAttrs (step.env != { }) { inherit (step) env; })
      (lib.optionalAttrs (step.github-actions != null) step.github-actions)
    ];

  # step (already checked) -> listOf attrs, for a non-block step.
  renderNonBlockStep =
    step:
    if step.run != null then
      [ (renderStepAttrs { inherit (step) run; } step) ]
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
          # Validate the block/inputs (unknown block, unknown input names);
          # defaults are not emitted, only the caller-supplied inputs are.
          validated = resolveInputs {
            inherit blocks;
            name = checked.block;
            inherit (checked) inputs;
          };
          leaves = instantiate {
            inherit blocks;
            forbidGithubActions = true;
          } checked;
        in
        if checked.block == null then
          renderNonBlockStep checked
        else if native then
          builtins.deepSeq validated [
            (renderStepAttrs (
              {
                uses = "./.github/actions/${checked.block}";
              }
              // lib.optionalAttrs (checked.inputs != { }) { "with" = checked.inputs; }
            ) checked)
          ]
        else
          lib.concatMap (leaf: renderNonBlockStep (leaf // { env = checked.env // leaf.env; })) leaves;
    in
    lib.concatMap renderStep;

  # Render a step's own run/raw lines, ignoring env/name (applied by the caller).
  # `raw` names the backend field whose raw lines this backend runs, if any.
  renderShellLeaf =
    raw: step:
    if step.run != null then
      [ step.run ]
    else if raw != null && step.${raw} != null then
      step.${raw}
    else
      # Raw step for another backend: dropped.
      [ ];

  # Wrap a step's rendered body lines with its own env (one collapsed shell
  # group) and then its name (start/end lines around the result). A step
  # with no lines (dropped raw step) renders nothing.
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
              lib.mapAttrsToList (k: v: ''${k}="${lib.escape [ "\\" "\"" "`" ] v}"'') step.env
            );
          in
          [ "( export ${exports}\n${lib.concatStringsSep "\n" lines}\n)" ]
        else
          lines;
      nl = nameLines id step.name;
    in
    if lines == [ ] then
      [ ]
    else if step.name != null then
      (lib.optional (nl.start != "") nl.start) ++ withEnv ++ (lib.optional (nl.end != "") nl.end)
    else
      withEnv;

  # { blocks, nameLines, raw } -> listOf step -> listOf str
  # Does not reuse `instantiate`: it needs a per-step path (not just the
  # flattened leaves) to derive stable section ids for nested blocks.
  toShellLines =
    {
      blocks,
      nameLines,
      raw ? null,
    }:
    let
      wrap = wrapShellStep { inherit nameLines; };

      renderSteps =
        stack: path: steps:
        lib.concatLists (lib.imap0 (i: renderStep stack (path ++ [ i ])) steps);

      renderStep =
        stack: path: step:
        let
          checked = checkStep step;
        in
        wrap {
          step = checked;
          lines =
            if checked.block == null then
              renderShellLeaf raw checked
            else
              renderSteps (stack ++ [ checked.block ]) path (blockSteps blocks stack checked);
          id = "step_${lib.concatStringsSep "_" (map toString path)}";
        };
    in
    renderSteps [ ] [ ];

  # { blocks } -> name -> attrs, a composite action.yml for one block.
  toGithubAction =
    { blocks }:
    name:
    let
      block = enterBlock blocks [ ] name;
      placeholderInputs = lib.mapAttrs (n: _: "\${{ inputs.${n} }}") block.inputs;
      # Composite action `run` steps require an explicit shell.
      steps = map (step: lib.optionalAttrs (step ? run) { shell = "bash"; } // step) (
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
