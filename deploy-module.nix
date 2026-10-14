{
  withSystem,
  ...
}:
{
  herculesCI = herculesCI: {
    onPush.default.outputs.effects.netlifyDeploy = withSystem "x86_64-linux" (
      perSystemArgs@{
        hci-effects,
        ...
      }:
      hci-effects.netlifyDeploy {
        content = perSystemArgs.config.packages.default;
        secretName = "default-netlify";
        siteId = "29a153b1-3698-433c-bc73-62415efb8117";
        productionDeployment = herculesCI.config.repo.branch == "main";
      }
    );
  };
}
