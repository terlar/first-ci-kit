{
  needs = [
    {
      stack = "infra";
      component = "db";
    }
  ];
}
