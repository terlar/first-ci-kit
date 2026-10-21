{
  needs = [
    { component = "db"; }
    { component = "net"; }
    { stack = "base"; }
  ];
}
