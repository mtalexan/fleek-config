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
- `custom-modules/` contains manually written modules that don't exist upstream
  - `home-manager/` are home-manager configuration modules
  - `overlay-packages` are for importing into the overlays defintiion of the flake, either add packages, override packages, or modify build definitions (implicitly overriding packages).
- `home_files/` directory structures of files that may need to be copied into place in the home folder by home-manager config settings. 
- `sd_scripts/` for the `sd` tool, the help text files and the scripts in the directories implicitly define a set of subcommands that are part of the path and include auto-complete.
- `secrets/` are the (r)agenix secrets for decryption with `agenix` home-manager module.
- `snippets/` are shell script files that get sourced into the shellrc files by home-manager config settings.


## Usage

Install Nix with the Determinate Nix Installer.
Note: You have to set the environment variable to the install command if you have custom Root CAs that need to be used.


### New System

Note: Items marked with `(A)` only need to be performed if you need agecrypt identity decryption for your new host.

1. Clone the repo into `~/.local/share/fleek`
2. Configure your git config `user.name` and `user.email` if you haven't already (these will be overridden later)
3. (A) Temporarily install `git agecrypt` with low priority using the repo's flake version: `nix profile install --priority 7 --inputs-from . 'git-agecrypt'`
4. (A) Enable agecrypt in the cloned repo: `git agecrypt init`
5. (A) Add the SSH encryption key for the `identities/*.nix` files to your `~/.ssh` (manual out-of-band process, make sure the private key has `600` permissions)
6. (A) Configure the private identity key(s) to use for agecrypt (repeat for all keys): `git agecrypt config add -i ~/.ssh/identity_private_key` 
7. (A) Confirm everything is setup properly for agecrypt: `git agecrypt status`
8. (A) Re-run the git smudge and textconv filtering on the files so the identities are decrypted
```shell
git rm --cached -r .
# this next command should end up listing only the files that were decrypted by agecrypt
git reset
git checkout .
```
9. Edit the `flake.nix`, copy-paste and edit one of the blocks that supply the config for a username and hostname, setting your `$(hostname)` and `$(id -u)`.
10. Copy then edit one of the `hosts/` config files, naming the new one `$(hostname)_$(id -u).nix`
11. Edit the newly created `hosts/` file to configure SSH key locations, desired tools, etc
12. Stage all files, especially the new ones, so they can be found by the `nix build`
13. (A) Manually run the update, which will fail the first time because it doesn't see the decrypted files for some reason: `bin/fleek-apply --impure`
14. Manually run the update (`--impure` is requried to use the new files without commiting them yet): `bin/fleek-apply --impure`
15. Commit all changes and push them to GitHub
16. (A) Remove `git-agecrypt` from your nix profile (it's provided by Home Manager now): `nix profile remove 'git-agecrypt'`

### Apply Changes

```shell
# alias
fleek-impure
# or non-alias
~/.local/share/fleek/bin/fleek-apply --impure
```

The `--impure` is required if you want uncommited (but tracked) files from this git repo to be included in the build.  
The `--impure` is also required if you use nixGL (i.e. `custom.nixGL.gpu = true` in your `hosts/*.nix` for the current system).


The `fleek-apply` script will be in your path after the first home-manager switch and can be called directly. Any options passed to it are passed to the home-manager package, it simply acts as a wrapper to ensure the home-manager from this git repo's flake defintiion is used, and UNFREE packages are allowed.

### Update Everything

```shell
fleeks
nix flake update
```
This updates the flake.lock with knowledge of the newer tools.  Changes still need to be applied with `fleek-apply`.  

Recommended to test the changes before commiting and pushing them, by doing `fleek-apply --impure` and verifying everything works as expected first.

### Secrets

Secrets come in two forms:
- Secrets used by tools installed by home-manager
- Secret `*.nix` files in the git repo that define the home-manager config

Shared secret keys used by tools home-manager installs might not be convenient to configure manually on every system. These make use of `agenix` to manually add them as encrypted `*.age` files in the `secrets/` folder.

Files that are part of the home-manager config itselt (*.nix files), but that contain private or secret values make use of `git-agecrypt` to automatically store them in git as encrypted `*.age` files, but make them visible unencrypted in your working directory.

#### Agenix Secrets

Secret files that don't need to be sourced by the home-manager config itself should be encrypted with (r)agenix in the `secrets/` folder. Unlike `identities/` files that have to be on-disk-readable at home-manager build time and therefore must use the very brittle `git-agecrypt`, secrets that are only needed at run time (like passwords or encryption keys) should use `agenix`/`ragenix`.  

1. Add the encrypted secret to the `secrets/` folder (see [secrets/secrets.nix](./secrets/secrets.nix) for details)
2. Ensure the `hosts/` file has a `age.identityPaths` value pointing to the location of an out-of-band private key matching one of the public keys listed in the `secrets.nix` for the file(s).
3. Add `age.secrets."secretname"` definition block to a *.nix file, making sure the `file` value is the path to the encrypted age file in the repo.
4. Use the `config.age.secrets."secretname".path` as a file path to the decrypted path.

See [programs/agenix.nix](./programs/agenix.nix) for a detailed breakdown of these steps.

#### Git-Agecrypt Secrets

These secrets are hard to verify they're doing what you want becuse they make use of git smudge filters to do automatic encryption/decryption of the files whenever the working copy of the repo is updated.  Effectively it automatically encrypts the files when you commit them, storing only the encrypted copy in the repo, and automatically decrypts them when you check the files out into your working copy.  

We make use of SSH keys as the asymmetric encryption/decryption keys for convenience. It's worth mentioning that you don't have to be able to decrypt every secret on every system, it will only decrypt the ones you have the keys for.

You must:
- Have `git-agecrypt` installed.
- Have one/some of the SSH key-pairs for the files to be decrypted
- Have run `git agecrypt init` in the cloned repo at least once
- Have configured one/some "identities" in the repo, pointing to the SSH private key(s) to use for decryption (`git agecrypt config add -i ~/.ssh/my_private_key`)


If you cloned the repo before doing these things, you'll need to force git to re-smudge all the files (this will wipe out any local changes!):
```shell
git rm --cached -r .
# this command should end up listing only the files that were decrypted by agecrypt
git reset
git checkout .
```

To add files, you need to (**BEFORE** committing the file):
- Register the file with git-agecrypt (`git agecrypt config add -r $(cat ~/.ssh/my_public_key.pub | awk '{print $1 $2 }') -p path/to/file_to_add`)
- Manually add the file to the `.gitattributes` so it gets smudged (see existing examples)

**WARNING:** If `git-agecrypt` gets updated, you must re-run `git agecrypt init` in your clone again to update the absolute path to the binary it will use!

## Troubleshooting

### Cannot connect to socket after ostree upgrade

After an ostree update you can no longer communicate with the nix-daemon socket.
```
error: cannot connect to socket at '/nix/var/nix/daemon-socket/socket': Connection refused
```
And the service isn't even found
```shell
$ sudo systemctl status nix-daemon.service
Unit nix-daemon.service could not be found.
```

This is an issue how SELinux file labels are improperly applied by ostree updates.  
You just need to manually tell SELinux to re-apply the file labels to the nix store, then tell systemd to rescan for service unit files, and re-enable the nix service unit that is now properly labeled.

```shell
sudo restorecon -Rv /nix
sudo systemctl daemon-reload
sudo systemctl enable nix-daemon.service
sudo systemctl start nix-daemon.service
```

It should now be working again.

_Source: https://github.com/DeterminateSystems/nix-installer/issues/829_
