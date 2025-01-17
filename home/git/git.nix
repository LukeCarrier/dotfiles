{
  gitConfig,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.meld ];

  home.shellAliases = {
    g = "git";
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Luke Carrier";
    userEmail = "luke@carrier.family";

    extraConfig = {
      branch.sort = "-committerdate";
      core.excludesfile = "~/.gitignore";
      init.defaultBranch = "main";
      interactive.singleKey = true;
      pull.ff = "only";

      diff.tool = "meld";
      merge.tool = "meld";

      safe.directory = [ "/etc/nixos" ];

      commit.gpgsign = true;
      gpg = {
        format = "ssh";
      };
      user.signingkey = gitConfig.user.signingKey;

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
  };
}
