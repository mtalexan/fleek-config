# Fleek Configuration

nix home-manager configs originally created by [fleek](https://github.com/ublue-os/fleek), but now ejected after it was deprecated.

## Reference

- [home-manager](https://nix-community.github.io/home-manager/)
- [home-manager options](https://nix-community.github.io/home-manager/options.html)

## Structure

The top level folder must contain the following files for it to work properly in different Nix use cases:
- flake.lock
- flake.nix
- home.nix
- path.nix
- shell.nix
- user.nix

`hosts/` contains the per-host config files. Under `fleek` these were `$hostname/custom.nix`.

Settings are split up into `modules/` and `programs/` that each of specific configs.  
- `programs/` are organized by the specific program they configure, and are only included if either the top-level `user.nix` or the host-specific Nix file list it.  
- `modules/` are alway included and may cover a range of settings in each module.

There are also top-level folders:
- `bin/` this folder is added to the PATH so in-place scripts and tools can be put in here.
- `home_files/` directory structures of files that may need to be copied into place in the home folder by home-manager config settings. 
- `sd_scripts/` for the `sd` tool, the help text files and the scripts in the directories implicitly define a set of subcommands that are part of the path and include auto-complete.
- `snippets/` are shell script files that get sourced into the shellrc files by home-manager config settings.


## Usage

Install Nix with the Determinate Nix Installer.
Note: You have to set the environment variable to the install command if you have custom Root CAs that need to be used.


### New System

1. Clone the repo into `~/.local/share/fleek`
2. Edit the `flake.nix`, copy-paste and then edit one of the blocks that config for the username and hostname.
3. Copy then edit one of the hostname config files

### Apply Changes

```shell
# alias
fleek-impure
# or non-alias
~/.local/share/fleek/bin/fleek-apply --impure
```

### Update Everything

```shell
fleeks
nix flake update
```
This updates the flake.lock with knowledge of the newer tools.

Then apply the changes.