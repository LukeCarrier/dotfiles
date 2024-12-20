{
  config,
  gitConfig,
  pkgs,
  ...
}:
{
  home.shellAliases = {
    g = "git";
  };

  programs.git.enable = true;
  programs.git.lfs.enable = true;
  programs.git.userName = "Luke Carrier";
  programs.git.userEmail = "luke@carrier.family";
  programs.git.signing.key = gitConfig.user.signingKey;

  programs.git.extraConfig = {
    branch.sort = "-committerdate";
    core.excludesfile = "~/.gitignore";
    init.defaultBranch = "main";
    interactive.singleKey = true;
    pull.ff = "only";

    diff.tool = "meld";
    merge.tool = "meld";

    safe.directory = [ "/etc/nixos" ];

    url."git@github.com:".insteadOf = "https://github.com/";

    alias = {
      a = "add";
      br = "branch";
      brl = "!git branch --format \"%(ahead-behind:HEAD)\t%(refname:short)\t%(committerdate:relative)\t%(describe)\" | git column";
      cm = "commit";
      cma = "commit --amend";
      cme = "commit --allow-empty";
      cman = "commit --amend --no-edit";
      cmf = "commit --fixup";
      co = "checkout";
      d = "diff";
      ds = "diff --staged";
      f = "fetch";
      l = "log";
      lg = "log --graph --oneline";
      mt = "mergetool";
      pf = "push --force-with-lease";
      pl = "pull";
      rb = "rebase --interactive --autostash --autosquash";
      rc = "rebase --continue";
      re = "reset";
      rs = "restore --staged";
      s = "status";
      st = "stash";
      sw = "switch";
      wc = "whatchanged";
    };
  };
}
