# do NOT import this into the flake.
# This is just the config file for (r)agenix to manage the *.age files in this folder.

# The ragenix commands must be run from this folder, or the '--rules=<path to this file>' must be used.

# To add a secret:
#  1. Add the intended name of the encrypted file to this list with the set of publicKeys that can decrypt it.
#  2. Run 'ragenix --identify=<path to private key> -e <path to encrypted file name>' for the new encrypted file name.
#  3. Paste the content to encrypt into the editor, then save and exit

let
  # variables holding public keys (only format and key portion of the pubkey file contents)
  fleek_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICnXa5Rrvr/A2wqt/4En+mKFLV/5+3WDGIV0nOx2INWE";
in
{
  # Each file in this folder needs to be listed here, with a list of public keys specified for encrypting it.
  # One of the matching private keys needs to be part of the homeage.identityPaths in the home-manager config
  # for a given to file to be decrypted. Files listed here that are encrypted with a key-pair homeage doesn't
  # point to will silently not be decrypted.

  "atuin_key.age".publicKeys = [ fleek_key ];
  "atuin_session.age".publicKeys = [ fleek_key ];
}