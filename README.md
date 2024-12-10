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
    apply-WINDOWS-GAMING = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@WINDOWS-GAMING";

    apply-bazzite = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@bazzite";

    apply-cloud-t610 = "nix run --impure home-manager/master -- -b bak switch --flake .#mike@cloud-t610";

    apply-fedora = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@fedora";

    apply-goln-422q533 = "nix run --impure home-manager/master -- -b bak switch --flake .#mtalexander@goln-422q533";

    apply-goln-5cl17g3 = "nix run --impure home-manager/master -- -b bak switch --flake .#mtalexander@goln-5cl17g3";

    apply-kubic-730xd = "nix run --impure home-manager/master -- -b bak switch --flake .#mike@kubic-730xd";

    apply-laptop = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen@laptop";

    apply-laptopFedora = "nix run --impure home-manager/master -- -b bak switch --flake .#aaravchen2@laptopFedora";

    apply-vm-gol-422Q533 = "nix run --impure home-manager/master -- -b bak switch --flake .#dev@vm-gol-422Q533";

    bathelp = "bat --plain --language=help";

    batpretty = "prettybat";

    cat = "bat";

    catp = "bat -P";

    fleek-impure = "fleek-apply --impure";

    fleeks = "cd ~/.local/share/fleek";

    gbc = "git branch --show-current";

    gbvv = "git branch -vv";

    gcm = "git commit";

    gd = "git diff";

    gdc = "git diff --cached";

    glg = "git log --oneline --decorate --graph";

    gs = "git status";

    la = "eza -a";

    ll = "eza -l";

    lla = "eza -l -a";

    llag = "eza -l -a --git";

    llg = "eza -l --git";

    ls = "eza";

    lt = "eza --tree";

    rgfzf = "sd rg-fzf";

    tree = "eza --tree";
