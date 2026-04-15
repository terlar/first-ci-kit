{ lib, config, ... }:

{
  imports = [
    ./interface.nix
    ./jobs
    ./job-interfaces
    ./job-sets
    ./pipelines
  ];

  config = {
    _module.args.ci-lib = import ./lib { inherit lib; };

    gitlab-ci.fileDocuments = lib.mkMerge [
      (lib.mkIf (config.gitlab-ci.inputs != { }) [
        { spec = { inherit (config.gitlab-ci) inputs; }; }
      ])
      [ config.gitlab-ci.settings ]
    ];
  };
}
