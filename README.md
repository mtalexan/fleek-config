# Fleek Configuration

nix home-manager configs created by [fleek](https://github.com/ublue-os/fleek).

## Reference

- [home-manager](https://nix-community.github.io/home-manager/)
- [home-manager options](https://nix-community.github.io/home-manager/options.html)

## Usage

Aliases were added to the config to make it easier to use. To use them, run the following commands:

```bash
# To change into the fleek generated home-manager directory
$ fleeks
# To apply the configuration
$ apply-$(hostname)
```

Your actual aliases are listed below:
    bathelp = "bat --plain --language=help";

    batpretty = "prettybat";

    cat = "bat";

    catp = "bat -P";

    fleek = "nix run github:ublue-os/fleek --";

    fleeks = "cd ~/.local/share/fleek";

    gbvv = "git branch -vv";

    gcm = "git commit";

    gd = "git diff";

    gdc = "git diff --cached";

    glg = "git log --oneline --decorate --graph";

    gs = "git status";

    la = "exa -a";

    latest-fleek-version = "nix run https://getfleek.dev/latest.tar.gz -- version";

    ll = "exa -l";

    lla = "exa -l -a";

    llag = "exa -l -a --git";

    llg = "exa -l --git";

    ls = "exa";

    lt = "exa --tree";

    rgfzf = "sd rg-fzf";

    tree = "exa --tree";

    update-fleek = "nix run https://getfleek.dev/latest.tar.gz -- update";
