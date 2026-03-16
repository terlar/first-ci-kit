{ lib, config, ... }:

{
  imports = [
    ./interface.nix
    ./jobs
    ./job-interfaces
    ./job-profiles
    ./job-sets
  ];

  config = {
    _module.args.ci-lib = import ./lib { inherit lib; };

    pipeline.gitlab-ci.fileDocuments = lib.mkMerge [
      (lib.mkIf (config.pipeline.gitlab-ci.inputs != { }) [
        { spec = { inherit (config.pipeline.gitlab-ci) inputs; }; }
      ])
      [ config.pipeline.gitlab-ci.settings ]
    ];
  };
}
