{ pkgs, ... }:
let
  terraformPlanHtml = pkgs.writeShellApplication {
    name = "terraform-plan-html";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./bin/terraform-plan-html.py} "$@"
    '';
  };
in
{
  home.packages = [ terraformPlanHtml ];
}
