{
  description = "Dependencies for development purposes";

  inputs = {
    dev-flake.url = "github:terlar/dev-flake";
    first-ci-kit.url = "github:terlar/first-ci-kit";
    process-compose.follows = "first-ci-kit/process-compose";
  };

  outputs = _: { };
}
