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
- `secrets/` are the (r)agenix secrets for decryption with `agenix` home-manager module.
- `snippets/` are shell script files that get sourced into the shellrc files by home-manager config settings.


## Usage

Install Nix with the Determinate Nix Installer.
Note: You have to set the environment variable to the install command if you have custom Root CAs that need to be used.


### New System

Note: Items marked with `(A)` only need to be performed if you need agecrypt identity decryption for your new host.

1. (A) Temporarily install `git agecrypt` with low priority: `nix profile install --priority=7 'nixpkgs#git-agecrypt'`
2. Clone the repo into `~/.local/share/fleek`
3. Configure your git config `user.name` and `user.email` if you haven't already
4. (A) Enable agecrypt in the cloned repo: `git agecrypt init`
5. (A) Configure the private identity key(s) to use for agecrypt (repeat for all keys): `git agecrypt config add -i ~/.ssh/identity_private_key` 
6. (A) Confirm everything is setup properly for agecrypt: `git agecrypt status`
7. (A) Re-run the git smudge and textconv filtering on the files so the identities are decrypted
```shell
git rm --cached -r .
# this command should end up listing only the files that were decrypted by agecrypt
git reset
git checkout .
```
8. Edit the `flake.nix`, copy-paste and then edit one of the blocks that config for the username and hostname.
9. Copy then edit one of the hostname config files, naming the new one `$(hostname)_$(id -u).nix`
10. Commit the changes so they're found by the nix build
11. Manually run the update: `bin/fleek-apply --impure`
12. Push the git commit
13. Remove `git-agecrypt` from your nix profile (it's provided by Home Manager now): `nix profile remove 'git-agecrypt'`

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


### Secrets

Secret files that don't need to be sourced by the home-manager config itself should be encrypted with (r)agenix in the `secrets/` folder. Unlike `identities/` files that have to be on-disk-readable at home-manager build time and therefore must use the very brittle `git-agecrypt`, secrets that are only needed at run time (like passwords or encryption keys) should use `agenix`/`ragenix`.  

1. Add the encrypted secret to the `secrets/` folder (see [secrets/secrets.nix](./secrets/secrets.nix) for details)
2. Ensure the `hosts/` file has a `age.identityPaths` value pointing to the location of an out-of-band private key matching one of the public keys listed in the `secrets.nix` for the file(s).
3. Add `age.secrets."secretname"` definition block to a *.nix file, making sure the `file` value is the path to the encrypted age file in the repo.
4. Use the `config.age.secrets."secretname".path` as a file path to the decrypted path.

See [programs/agenix.nix](./programs/agenix.nix) for a detailed breakdown of these steps.