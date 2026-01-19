# Nix Home Manager Configuration

nix home-manager configs originally created using [fleek](https://github.com/ublue-os/fleek) (now deprecated), but significantly modified from the original state.

## Reference

- [home-manager](https://nix-community.github.io/home-manager/)
- [home-manager options](https://nix-community.github.io/home-manager/options.html)

## Structure

The top level folder must contain the following files for it to work properly in different Nix use cases (**not sure what the non-`flake.*` are expected to provided!**):
- flake.lock
- flake.nix
- home.nix
- path.nix
- shell.nix
- user.nix

`hosts/` contains the per-host config files. Roughly equivalent to `fleek`'s `$hostname/custom.nix` files.

Settings are split up into `modules/` and `programs/` that each of specific configs.  
- `programs/` are organized by the specific program they configure, and are only included if `all.nix` or the host-specific Nix file list it.  
- `modules/` are always included and may cover a range of settings in each module. The main one is `all.nix`.

There are also top-level folders:
- `bin/` this folder is added to the PATH so in-place scripts and tools can be put in here.
- `custom-modules/` contains manually written modules that don't exist upstream.
  - `home-manager/` are home-manager configuration modules, they define a set 
  - `overlay-packages/` are for importing into the overlays definition of the flake, either add packages, override packages, or modify build definitions (implicitly overriding packages).
- `home_files/` directory structures of files that may need to be copied into place in the home folder by home-manager config settings. 
- `sd_scripts/` for the `sd` tool, the help text files and the scripts in the directories implicitly define a set of subcommands that are part of the path and include auto-complete.
- `secrets/` are the (r)agenix secrets for decryption with `agenix` home-manager module.
- `snippets/` are shell script files that get sourced into the shellrc files by home-manager config settings.


## Usage

Install Nix with the Determinate Nix Installer.  You MUST use the Determinate Nix fork of Nix!

### Install Nix

Determinate Nix has its own fork of Nix that is mostly fixes and feature additions to upstream Nix that haven't been merged yet.  It prioritizes user friendliness, unlike upstream Nix, and gets fixes for bugs faster.  

**Note:** Using upstream Nix, or Lix will cause the `flake.lock` here to mismatch the source URLs of what's pinned and the `flake.lock` will have to be manually updated independently on any system that isn't using the same fork of the Nix tool.

Instructions adapted from: https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#installer-settings

`ostree`-based distros are more complicated since they restrict the ability to modify `/`.  Unfortunately `nix` still has no good way to locate the system nix store anywhere other than `/nix`, so workarounds are difficult.  
**WARNING:** ostree-based distros require you to manually create the `/nix` mountpoint before running the intaller since the installer can't do it for you on these system types.  When the distro uses composefs (e.g. anything based on Fedora >= 42) however, this is not possible without creating your own distro fork (see UBlue directions for doing this easily via GitHub actions).  

1. If you're on an ostree-based distro without composefs, create the nix store mountpoint.
```shell
# for Fedora-based systems
sudo ostree admin unlock --hotfix
# for OpenSUSE based systems
sudo transaction-manager --shell --continue

sudo mkdir /nix
# If this command fails with a permissions error, you're on a distro using composefs that requires you to create your own ostree fork build in order to add this folder instead.

# for OpenSUSE, exit the subshell so the new ostree commit is applied and set as the next to boot
exit

# You MUST reboot immediately after the hotfix is created on Fedora-based systems, any additional changes to the unlocked system are also permanent.
# For Fedora and OpenSUSE based systems, you need to reboot into the new ostree commit to see the changes (requires a clean reboot to work)
sudo systemctl reboot
```

2. Run the installer, installing the Determinate Nix fork of `nix`, and using the host Root CAs
```shell
# WARNING: The install help text is wrong, none of the CLI options work when you have to specify the plan (e.g. ostree)

# Set the path to your system-specific Root CA Certificate bundle file so any custom Root CAs are respected.

# On most systems
export NIX_INSTALLER_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
# On OpenSUSE systems
export NIX_INSTALLER_SSL_CERT_FILE=/etc/ssl/ca-bundle.pem

# Make sure your system's curl is using the same path
export CURL_CA_BUNDLE=$NIX_INSTALLER_SSL_CERT_FILE

# non-ostree
NIX_INSTALLER_DETERMINATE=true curl -fsSL https://install.determinate.systems/nix | sh -s -- install
# or ostree (auto-detection doesn't work, so it must be specified manually)
NIX_INSTALLER_DETERMINATE=true curl -fsSL https://install.determinate.systems/nix | sh -s -- install ostree
```

3. (on SELinux systems sometimes) Apply SELinux labels to the nix store
```shell
sudo restorecon -R /nix
```
**WARNING:** You may need to re-run this SELinux relabel command after every system update (esp. on OpenSUSE ostree distros).  
**WARNING:** After you run this, you will need to re-fix the SELinux context on the file pointed to by `/etc/systemd/system/non-nixos-gpu.service`

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
11. Edit the newly created `hosts/` file to configure SSH key locations, desired tools, etc. Don't forget to set the GPU driver version to match your actual system's NVIDIA driver version!
12. Stage all files, especially the new ones, so they can be found by the `nix build`  
13. (A) Manually run the update, which will fail the first time because it doesn't see the decrypted files for some reason: `bin/fleek-apply --impure`  
14. Manually run the update (`--impure` is required to use the new files without committing them yet): `bin/fleek-apply --impure`  
15. Setup GPU support. There will usually be a warning from home-manager about GPU support not being setup:  
```
This non-NixOS system is not yet set up to use the GPU
with Nix packages. To set up GPU drivers, run
  sudo /nix/store/q8phx7jadr846rw1i7lr1m476h8iwhwp-non-nixos-gpu/bin/non-nixos-gpu-setup
```
Run the command you see in your specific warning to have it setup a root `non-nixos-gpu.service` that symlinks the GPU libraries into a `/run/` folder for Nix programs to use.  
WARNING: This command will fail on SELinux systems until you manually correct the SELinux context of the service file it symlinks to. See below.  
16. Double check the GPU setup by looking at the contents of `/run/opengl-driver/share/vulkan/icd.d/` to make sure your GPU type is included (especially for NVIDIA GPUs).  
17. Commit all changes and push them to GitHub.  
18. (A) Remove `git-agecrypt` from your nix profile (it's provided by Home Manager now): `nix profile remove 'git-agecrypt'`  
19. Setup Atuin: `atuin account login` (keys are the same and already provisioned), then `atuin sync`.

### Host System Updates

When you update your host system, the GPU integration will break.  
If you have an NVIDIA GPU, you will need to modify the NVIDIA driver version in your `hosts/*.nix` file to match the new driver version.  
Regardless of whether you have an NVIDIA GPU or not, you should also re-run the `fleek-apply --impure` commend so it will regenerate the host integration. This may warn you that you need to re-run the GPU setup script again.  

If your host system uses SELinux, your nix store will probably also break. You'll need to manually re-run:
```shell
sudo restorecon -R /nix
```

**WARNING:** After you run this, you will need to re-fix the SELinux context on the file pointed to by `/etc/systemd/system/non-nixos-gpu.service`


### Apply Changes

```shell
# alias
fleek-impure
# or non-alias
~/.local/share/fleek/bin/fleek-apply --impure
```

The `--impure` is required if the config for the specific host includes any non-free packages (e.g. VSCode).  
The `--impure` is required if you want uncommitted (but tracked) files from this git repo to be included in the build.  


The `fleek-apply` script will be in your path after the first home-manager switch and can be called directly. Any options passed to it are passed to the home-manager package, it simply acts as a wrapper to ensure the home-manager from this git repo's flake definition is used, and UNFREE packages are allowed.

**WARNING:** You may need to re-run this after every host system update!  
**WARNING:** Watch for build warnings, especially the home-manager GPU setup warning that can re-appear after a host system update!  

### Updates

To update all the flakes, which effectively updates all packages, run the command:

```shell
fleeks
nix flake update
```
This updates the flake.lock with knowledge of the newer tools.  Changes still need to be applied with `fleek-apply`.  

Recommended to test the changes before committing and pushing them, by doing `fleek-apply --impure` and verifying everything works as expected first.

#### Only Specific Flakes

The VSCode and Zed tools are split out into their own flakes specifically to allow them to be updated separately from the rest of the packages.  
These can be updated to be newer, but there's a limit on how much newer since they still pull many of their common dependencies from the `nixpkgs` flake.

```shell
fleeks
nix flake update vscode-nixpkgs zed-nixpkgs
```

Examine the `inputs` section of the `flake.nix` to find the names of the flakes. Notably, anything set to follow `nixpkgs` cannot be independently updated, it will instead need to be updated along with the `nixpkgs` flake.

### Secrets

Secrets come in two forms:
- Secrets used by tools installed by home-manager
- Secret `*.nix` files in the git repo that define the home-manager config

Shared secret keys used by tools home-manager installs might not be convenient to configure manually on every system. These make use of `agenix` to manually add them as encrypted `*.age` files in the `secrets/` folder.

Files that are part of the home-manager config itself (*.nix files), but that contain private or secret values make use of `git-agecrypt` to automatically store them in git as encrypted `*.age` files, but make them visible unencrypted in your working directory.

#### Agenix Secrets

Secret files that don't need to be sourced by the home-manager config itself should be encrypted with (r)agenix in the `secrets/` folder. Unlike `identities/` files that have to be on-disk-readable at home-manager build time and therefore must use the very brittle `git-agecrypt`, secrets that are only needed at run time (like passwords or encryption keys) should use `agenix`/`ragenix`.  

1. Add the encrypted secret to the `secrets/` folder (see [secrets/secrets.nix](./secrets/secrets.nix) for details)
2. Ensure the `hosts/` file has a `age.identityPaths` value pointing to the location of an out-of-band private key matching one of the public keys listed in the `secrets.nix` for the file(s).
3. Add `age.secrets."secretname"` definition block to a *.nix file, making sure the `file` value is the path to the encrypted age file in the repo.
4. Use the `config.age.secrets."secretname".path` as a file path to the decrypted path.

See [programs/agenix.nix](./programs/agenix.nix) for a detailed breakdown of these steps.

#### Git-Agecrypt Secrets

These secrets are hard to verify they're doing what you want because they make use of git smudge filters to do automatic encryption/decryption of the files whenever the working copy of the repo is updated.  Effectively it automatically encrypts the files when you commit them, storing only the encrypted copy in the repo, and automatically decrypts them when you check the files out into your working copy.  

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

**WARNING:** After you run this, you will need to re-fix the SELinux context on the file pointed to by `/etc/systemd/system/non-nixos-gpu.service`

It should now be working again.

_Source: https://github.com/DeterminateSystems/nix-installer/issues/829_

### Builder for `luajit` or other neovim plugin dependency failed with exit code 2

When you get an error that looks like this:

```
error: builder for '/nix/store/xjcycf4fb9d4k31yz9nqgi9a61n3mqxb-luajit2.1-fzf-lua-0.0.1848-1.drv' failed with exit code 2;
       last 10 log lines:
       >   24|
       >   25|
       >   26|
       >   27|
       >   28|
       >   Traceback:
       >     /build/source/lua/fzf-lua/test/helpers.lua:254
       >     tests/file/ui_spec.lua:185
       >
       > make: *** [Makefile:15: test] Error 1
       For full logs, run 'nix log /nix/store/xjcycf4fb9d4k31yz9nqgi9a61n3mqxb-luajit2.1-fzf-lua-0.0.1848-1.drv'.
error: 1 dependencies of derivation '/nix/store/zckwv2vmraippx6wfnall9d4kj2jr2ly-vimplugin-luajit2.1-fzf-lua-0.0.1848-1-unstable-0.0.1848-1.drv' failed to build
```

It usually means that too many things were trying to build for your system at the same time, and you just need to keep retrying until it finally completes successfully:
```shell
while true; do fleek-impure ... && break; done
```

The Neovim plugins (like the one shown) seem to be the first to fail for some reason. It's unclear why an overloaded set of nix builders will cause build failures rather than just taking a long time, but that's what happens.  Some of the tools, like `emacs-unstable` and `zed-editor`, are quite large and can take a lot of time and resources to build. When this is needed during a rebuild, it can starve something and the neovim plugins (and their dependencies) are the first to fail out.

### Git-LFS error when using zed-editor flake

If you're using the Lix fork of Nix, it has problems as of version 2.23 with its implementation of how it does the `git lfs fetch` portion of the `fetchGit` function.  It seems to be related specifically to Rust crates on flakes making use of Crane for the Crate-to-Nix support when the crate has GitLFS objects in it.  It gets an error from GitLFS for some reason, which causes a cloning failure.

The work around is to not use Lix.

### git-agecrypt error when updating the repo

You get an error that looks something like this when you update the branch/commits in the cloned repo:
```shell
/nix/store/xh3hcnc210x77bb1hkyvg8vg7nn015lq-git-agecrypt-0.2.1/bin/git-agecrypt smudge -f 'identities/ks.nix': line 1: /nix/store/xh3hcnc210x77bb1hkyvg8vg7nn015lq-git-agecrypt-0.2.1/bin/git-agecrypt: No such file or directory
error: external filter '/nix/store/xh3hcnc210x77bb1hkyvg8vg7nn015lq-git-agecrypt-0.2.1/bin/git-agecrypt smudge -f %f' failed 127
error: external filter '/nix/store/xh3hcnc210x77bb1hkyvg8vg7nn015lq-git-agecrypt-0.2.1/bin/git-agecrypt smudge -f %f' failed
fatal: identities/ks.nix: smudge filter git-agecrypt failed
```

This is caused by the `git-agecrypt` absolute path in git config referring to a version of `git-agecrypt` that has been garbaged collected from the nix store.  
The path in the config is only updated when you run `git agecrypte init`, but as configurations change newer versions of `git-agecrypt` will be configured in the home-manager config. The older version get garbage collected.

Solution: run `git agecrypt init` again. The config in the repo will be updated to point to the current version.

### GPU Setup script errors out

When running the GPU setup script in the warning message, an access denied error occurs:

```
$ sudo /nix/store/q8phx7jadr846rw1i7lr1m476h8iwhwp-non-nixos-gpu/bin/non-nixos-gpu-setup

Failed to enable unit: Access denied
```

This is caused by the system using SELinux, and the home-manager generating the GPU configuration file without proper SELinux contexts.  

Solution:
1. Refresh the SELinux contexts on everything in `/nix`
```shell
sudo restorecon -Rv /nix
```

2. determine the correct SELinux context (which is assigned to the symlink that was created), and what the symlink points to:
```
ls -lZ /etc/systemd/system/non-nixos-gpu.service
```

3. Copy that context and symlink destination and use it as the arguments to the `chcon` command to set the proper SELinux context on the destination file:
```
sudo chcon unconfined_u:object_r:systemd_unit_file_t:s0 /nix/store/q8phx7jadr846rw1i7lr1m476h8iwhwp-non-nixos-gpu/resources/non-nixos-gpu.service
```

4. Re-run the GPU setup script.

#### Quick Alternative

Running GPU setup script will always create the same symlink (`/etc/systemd/system/non-nixos-gpu.service`) if it doesn't already exist, and make sure it points to the correct location in the nix store. After it fails, we can quickly determine and correct the permissions with a couple fixed commands:
```shell

sudo restorecon -v /etc/systemd/system/non-nixos-gpu.service
sudo restorecon -Rv /nix
sudo chcon $(stat -c '%C' /etc/systemd/system/non-nixos-gpu.service) $(readlink -e /etc/systemd/system/non-nixos-gpu.service)
```

_This makes sure the correct SELinux label is on the file in the systemd folder, then makes sure the nix store is all properly labeled, then finally assigns/corrects the label on the systemd service unit file in the nix store so it matches what is required at the destination it is symlinked to._
