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

    fleeks = "cd ~/.local/share/fleek";

    gbvv = "git branch -vv";

    gcm = "git commit";

    gd = "git diff";

    gdc = "git diff --cached";

    glg = "git log --oneline --decorate --graph";

    gs = "git status";

    la = "exa -a";

    ll = "exa -l";

    lla = "exa -l -a";

    llag = "exa -l -a --git";

    llg = "exa -l --git";

    ls = "exa";

    lt = "exa --tree";

    tree = "exa --tree";
