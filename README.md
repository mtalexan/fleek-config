# Nix Home Manager Configuration

nix home-manager configs originally created using [fleek](https://github.com/ublue-os/fleek) (now deprecated), but significantly modified from the original state.

## Reference

- [home-manager](https://nix-community.github.io/home-manager/)
- [home-manager options](https://nix-community.github.io/home-manager/options.html)

## Structure

```
./
├── flake.lock                        # Pinned flake inputs
├── flake.nix                         # Flake definition
├── home.nix                          # (not sure what the non-flake.* are expected to provide!)
├── path.nix                          #
├── shell.nix                         #
├── user.nix                          #
├── hosts/                            # Per-host config files
├── modules/                          # Always included, may cover a range of settings in each module.
├── programs/                         # Per-program configs that are each included only if referenced by a host config or the modules/all.nix
├── bin/                              # Added to PATH — in-place scripts and tools
├── chezmoi/                          # Chezmoi source state directory (see Chezmoi Managed Configs)
├── custom-modules/                   # Manually written modules that don't exist upstream
│   ├── home-manager/                 # Home-manager configuration modules
│   └── overlay-packages/             # For importing into ovarlay definitions in the flake.nix, either add packages, override packages, or modify build definitions
├── home_files/                       # File trees to be copied into ~ by home-manager config
├── identities/                       # `git-agecrypt` encrypted identity files for configurations of different identity-linked settings.
├── sd_scripts/                       # `sd` tool scripts. Help text files and scripts that implicitly define a set of subcommands with auto-complete that are part of the PATH
├── secrets/                          # (r)agenix secrets for decryption with `agenix` home-manager module
└── snippets/                         # Shell script files sourced into shellrc by home-manager config
```


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

Secrets come in three forms:
- git-agecrypt: Files that are encrypted in git, but not in a clone that has the proper key(s)
- Chezmoi age: Secrets used by chezmoi, and decrypted at run-time when chezmoi applies the config
- (r)agenix: other secrets that are used at run-time by tools but are stored encrypted

All three types of secrets make use of Age encryption, leveraging SSH keys for asymmetrical encryption/decryption. The pubilc SSH key is used to encrypt the secrets, and the private SSH key is used to decrypt them. All SSH keys for this are managed out-of-band from this configuration.

The git-agecrypt secrets use the `git-agecrypt` tool to do `age` encryption/decryption as a git repo filter. The configuration ends up as part of the local cloned repo's config.  

The `chezmoi` `age` secrets make use of explicit calls by `chezmoi` to the `age` CLI tool for when they should be decrypted, i.e. when `chezmoi apply` is run. The creation of the encrypted files is manual.  

Shared secrets that may be used on the system at run-time by tools make use of the `agenix` tool, which does system run-time decryption into a well-defined temporary system location. They are available to anyone on the system able to access the `agenix` decrypted folder.

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

### Chezmoi Managed Configs

While home-manager is great for declarative configurations, many tools, like IDEs, don't easily support declaring a complete config in Nix, and instead work much better if they can be modified in-place at run-time and have changes adopted back into the version controlled source for the config file. [Chezmoi](https://www.chezmoi.io/) excels at this, supporting the ability to do diff and reverse-diff between the config that is currently configured to be generated, and the current config file state, while still allowing conditional templating of the generated configs.  

Secrets still need to be kept secret however, so they are `age` encrypted files using public SSH keys as the key to encrypt with, and private SSH keys as the key to decrypt with. The secrets are decrypted by chezmoi directly from the encrypted files in the chezmoi config folder, which allows standard chezmoi tools to work directly with the encrypted files without ever exposing the secrets anywhere else.

#### How It Works

1. Home-manager installs `chezmoi` and `age`, and generates `~/.config/chezmoi/chezmoi.toml` with host-specific template data.
2. A home-manager activation script runs `chezmoi apply` at the end of every `home-manager switch`/`fleek-apply`.
3. Chezmoi reads its source directory (`chezmoi/` in this repo), evaluates Go templates, decrypts secrets, and writes the final config files to their target locations (e.g. `~/.config/zed/settings.json`).

Secrets are **never** stored in the nix store in the clear, or in git. They remain age-encrypted in the repo and are decrypted only at `chezmoi apply` time by the `age` CLI using SSH private keys present on the host.

Since all the template values defined in the home-manager config are inserted as data into the `chezmoi.toml` config file, standard `chezmoi` commands will operate with the static values from the current home-manager generation.

#### Directory Structure

```
chezmoi/                              # Chezmoi source state directory
├── .chezmoiignore.tmpl               # Controls which files are skipped per-host
├── .chezmoitemplates/                # Reusable template helpers
│   ├── age-decrypt-string            # Decrypt a secret, trim whitespace (single-line)
│   └── age-decrypt-block             # Decrypt a secret, preserve whitespace (multi-line)
├── .chezmoisecrets/                  # Age-encrypted secret values
│   └── <program>/                    # One subdirectory per program
│       └── <secret_name>.age          # Maps to .secrets.<program>.<secret_name>
└── dot_config/                       # Maps to ~/.config/
    └── <program>/                    # One directory per managed program
        ├── some_file.json.tmpl       # Templated file (Go template syntax)
        ├── other_file.json           # Static file (copied as-is)
        └── subdir/                   # Subdirectories are fine
```

Chezmoi naming conventions:
- `dot_` prefix → becomes a `.` in the target path (e.g. `dot_config/` → `~/.config/`)
- `.tmpl` suffix → file is processed as a Go template before writing
- Files without `.tmpl` are copied verbatim

#### Adding a New Program to Chezmoi

1. **Create the source files** in `chezmoi/dot_config/<program>/`, or whevever the file needs to be placed in the home folder:
   - Static files go in directly (e.g. `keymap.json`)
   - Files needing host-specific values or secrets get a `.tmpl` suffix (e.g. `settings.json.tmpl`)

2. **Add an ignore rule** in `chezmoi/.chezmoiignore.tmpl`:
   ```
   {{ if not (and (hasKey . "my_program") .my_program.enable) }}
   .config/my-program/**
   {{ end }}
   ```

This populates an **ignore** list of program directories based on the `.<program>.enable` field in the `chezmoi.toml` config data. The `hasKey` guard handles the case where the program module isn't imported at all.

3. **Register with chezmoi** in the program's `programs/<program>.nix`:
   ```nix
   custom.chezmoi.templates.my_program = {
     # Controls .chezmoiignore — when true, chezmoi manages this program's files
     enable = true;

     # Pass any template data (exposed as .my_program.<key> in templates)
     data = {
       some_setting = config.custom.my_program.some_option;
     };
   };
   ```

The `custom.chezmoi.templates.<program>` entries get inserted into the `chezmoi.toml` config file as data when home-manager generates the file. Each program's data is structured as `.<program>.*` (with `.enable` and `.secrets` as reserved sibling keys). Chezmoi includes that data when processing the template files supplied to it.

4. **Register secrets with chezmoi** in the program's `programs/<program>.nix` if needed (see next section)

#### Writing Templates

Chezmoi templates use [Go template syntax](https://pkg.go.dev/text/template). Template data from `custom.chezmoi.templates.<program>.data` is available as `.<program>.<key>`.

For a program registered with `custom.chezmoi.templates.zed.data = { copilot = true; }`, the template accesses it as:
```
{{- if .zed.copilot }}
  "edit_predictions": {
    "provider": "copilot"
  },
{{- end }}
```

Key syntax notes:
- `{{- ... -}}` trims surrounding whitespace
- `{{ if .field }}...{{ end }}` for conditionals
- `{{ .field.subfield }}` for nested data access
- `{{ includeTemplate "template-name" .data }}` to call a reusable template with an object (`.data`) as the context

#### Defining and Using Secrets

Secrets use age encryption. The system uses key classes — named references to age identity (private key) files that are defined per-host along with their corresponding recipient (public key) strings.

##### 1. Define key classes on the host

In `hosts/<host>_<user>.nix`, declare which age key classes are available and where to find them:
```nix
custom.chezmoi.config.age_keys = {
  work = {
    secret_file = "${config.home.homeDirectory}/.age/fleek_chezmoi_work";
    recipient = "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p";
  };
  # personal = {
  #   secret_file = "${config.home.homeDirectory}/.age/personal_key";
  #   recipient = "age1...";
  # };
};
```

##### 2. Encrypt the secret value

Use one of the `bin/chezmoi-age-encrypt-*` helper scripts depending on the key type:

**For age secret key files** (where the public key is derived from the secret key):
```shell
echo -n "my-secret-token" | bin/chezmoi-age-encrypt-age ~/.age/fleek_chezmoi_work > chezmoi/.chezmoisecrets/my_program/my_secret.age
```

**For SSH public key files** (where the `.pub` file is used directly as the recipient):
```shell
echo -n "my-secret-token" | bin/chezmoi-age-encrypt-ssh ~/.ssh/my_key.pub > chezmoi/.chezmoisecrets/my_program/my_secret.age
```

`chezmoi-age-encrypt-age` calls `age-keygen -y` on the secret key file to derive the recipient public key, then encrypts.
`chezmoi-age-encrypt-ssh` strips the optional comment field (column 3) from the SSH public key that `age` is sensitive to, then encrypts.
Both produce armored (ASCII-safe) output suitable for storage in git.

##### 3. Register the secret in the program module the secret is used for

In `programs/<program>.nix`, register the secret within the program's `templates` entry. Secrets are part of the unified per-program configuration:
```nix
# Registers as .my_program.secrets.my_secret in chezmoi templates
# Encrypted file: chezmoi/.chezmoisecrets/my_program/my_secret.age
custom.chezmoi.templates.my_program = {
  enable = true;
  secrets = lib.mkIf config.custom.my_program.needs_secret {
    my_secret.keyClass = "work";
  };
};
```

The directory convention `chezmoi/.chezmoisecrets/<program>/<secret_name>.age` is derived from the attribute names. The `encryptedFile` option defaults to `<secret_name>.age` but can be overridden if the filename differs from the attribute name.

The `keyClass` is resolved to an actual file path at evaluation time using the host's `custom.chezmoi.config.age_keys` map.

##### 4. Use the secret in a template

Call the reusable decrypt templates. Secrets are accessed as `.<program>.secrets.<secret_name>`:
```
// Single-line secret (token, password, API key):
"api_token": "{{ includeTemplate "age-decrypt-string" .my_program.secrets.my_secret }}",

// Multi-line secret (PEM certificate, SSH key, config block):
{{ includeTemplate "age-decrypt-block" .my_program.secrets.my_secret }}
```

`age-decrypt-string` trims whitespace/newlines; `age-decrypt-block` preserves them verbatim.

#### Example: Zed Editor

The Zed editor config demonstrates all of these features:

- **`programs/zed-editor.nix`** defines `custom.zed.gitlab_mcp.{enable,url}` and `custom.zed.copilot` options
- **`programs/zed-editor.nix`** registers `custom.chezmoi.templates.zed` with `enable = true`, template data, and secrets
- **`programs/zed-editor.nix`** registers the secret as `custom.chezmoi.templates.zed.secrets.gitlab_pat` using the `work` key class
- **`identities/{identity}.nix`** sets `custom.zed.gitlab_mcp.url` (private value, kept in git-agecrypt encrypted file)
- **`hosts/{host}.nix`** enables the zed feature flags (`gitlab_mcp.enable`, `copilot`) and defines the `work` key class
- **`chezmoi/dot_config/zed/settings.json.tmpl`** conditionally renders the GitLab MCP block and Copilot blocks based on the boolean flags and values
  - The GitLab MCP block uses `{{ includeTemplate "age-decrypt-string" .zed.secrets.gitlab_pat }}` to decrypt the PAT inline
- **`chezmoi/dot_config/zed/keymap.json`** and **`themes/`** are static files managed by chezmoi without templating

Host file configuration (`hosts/{host}.nix`):
```nix
custom = {
  chezmoi.config.age_keys.work = {
    secret_file = "${config.home.homeDirectory}/.age/fleek_chezmoi_work";
    recipient = "age1...";
  };
  zed = {
    gitlab_mcp.enable = true;
    copilot = true;
  };
};
```

Identity file configuration (`identities/{identity}.nix` — git-agecrypt encrypted):
```nix
# Private URL kept out of plaintext in the repo
custom.zed.gitlab_mcp.url = "https://gitlab.example.com/api/v4";
```

#### Importing run-time changes into declarative config

To see the list of files that are different between the current chezmoi source state and the generated config files on disk, run:
```shell
chezmoi status
```

To see an actual diff between what chezmoi would generate and what's on disk:
```shell
chezmoi diff
# or visa versa
chezmoi diff --reverse
```

For non-templated files that are just included as-is:
```shell
chezmoi re-add ~/path/to/file
```

To do a 3-way merge between the current file (`.Destination`), what's in the git repo (`.Source`), and what chezmoi would apply (`.Target`):
```shell
chezmoi merge ~/path/to/file
# or to merge them all
chezmoi merge-all
```

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
# Run the GPU setup script

sudo restorecon -v /etc/systemd/system/non-nixos-gpu.service
sudo restorecon -Rv /nix
sudo chcon $(stat -c '%C' /etc/systemd/system/non-nixos-gpu.service) $(readlink -e /etc/systemd/system/non-nixos-gpu.service)

# Re-run the GPU setup script
```

_This makes sure the correct SELinux label is on the file in the systemd folder, then makes sure the nix store is all properly labeled, then finally assigns/corrects the label on the systemd service unit file in the nix store so it matches what is required at the destination it is symlinked to._
