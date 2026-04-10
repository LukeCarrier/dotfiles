{lib}:
{
  substitute = config: lib: text:
    let
      placeholders = ["@TOKEN@" "@URL@" "@SERVICE_ACCOUNT_TOKEN@" "@CORALOGIX_UK_NONPROD_API_KEY@" "@CORALOGIX_UK_PROD_API_KEY@" "@CORALOGIX_US_NONPROD_API_KEY@" "@CORALOGIX_US_PROD_API_KEY@"];
      active = builtins.filter (p: lib.hasInfix p text) placeholders;
      secretMap = {
        "@TOKEN@" = "opencode-github-token";
        "@URL@" = "grafana-cloud-url";
        "@SERVICE_ACCOUNT_TOKEN@" = "grafana-cloud-service-account-token";
        "@CORALOGIX_UK_NONPROD_API_KEY@" = "coralogix-uk-nonprod-api-key";
        "@CORALOGIX_UK_PROD_API_KEY@" = "coralogix-uk-prod-api-key";
        "@CORALOGIX_US_NONPROD_API_KEY@" = "coralogix-us-nonprod-api-key";
        "@CORALOGIX_US_PROD_API_KEY@" = "coralogix-us-prod-api-key";
      };
      replacements = map (p: config.sops.placeholder.${secretMap.${p}}) active;
    in
    if active == [] then text else builtins.replaceStrings active replacements text;
}
