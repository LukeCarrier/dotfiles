{ ... }:
{
  nix.settings = {
    trusted-substituters = [
      "https://throwparty-agentkit.cachix.org"
      "https://throwparty-docusaurus-contrib.cachix.org"
      "https://throwparty-handbook.cachix.org"
      "https://throwparty-nix.cachix.org"
    ];
    trusted-public-keys = [
      "throwparty-agentkit.cachix.org-1:DP9UBQcVaYPOInupMNFyMdbt7ThC3HlRC6qqBscjBsM="
      "throwparty-docusaurus-contrib.cachix.org-1:peiO9GpCiaFwr1wdRnKp9FYq2N8gjHFPtoPwqdnXCSM="
      "throwparty-handbook.cachix.org-1:QBib/mvRrH2l1xddOy0+GTWtdhdQlKabfRguiKcY07Q="
      "throwparty-nix.cachix.org-1:6F8O6+jWb5t7vJ/+B54exADmRa4nfkZ+4ecLjfdrKjE="
    ];
  };
}
