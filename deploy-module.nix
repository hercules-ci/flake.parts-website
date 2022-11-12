{ config, lib, inputs, withSystem, ... }:
{
  herculesCI = herculesCI@{ config, ... }: {
    onPush.default.outputs.effects.netlifyDeploy =
      withSystem "x86_64-linux" ({ config, pkgs, hci-effects, ... }:
        hci-effects.netlifyDeploy {
          content = config.packages.siteContent;
          secretName = "default-netlify";
          siteId = "29a153b1-3698-433c-bc73-62415efb8117";
          productionDeployment = herculesCI.config.repo.branch == "main";
        }
      );
  };
}
