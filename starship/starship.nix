{ config, pkgs, ... }:
{
  programs.starship.enable = true;
  programs.starship.settings = {
    battery.disabled = true;
    c.disabled = false;
    kubernetes.disabled = false;
    time.disabled = false;

    custom.vault = {
      command = "timeout 0.2 vault status -format=json | jq -r .cluster_name";
      when = "timeout 0.2 vault status";
      format = "in [⩔ $output]($style) ";
    };

    directory = {
      truncation_length = 8;
      truncation_symbol = "…/";
    };

    git_status = {
      ahead = "⇡\${count}";
      diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
      behind = "⇣\${count}";
    };

    shell = {
      disabled = false;
      unknown_indicator = "⁉️";
      bash_indicator = "\\$_";
      fish_indicator = "🐠";
      powershell_indicator = ">_";
      zsh_indicator = "%_";
    };

    status = {
      disabled = false;
      symbol = "✖ ";
    };
  };
}
