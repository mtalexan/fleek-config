The files in this directory are used with the `home.file.<name>` configurations.  

Subfolders here come in two forms.  Either they're a directory that should always unconditionally be copied into a destination, or they're prefaced with `template_` and they represent a complete set of options.  

Template folders should be used by creating a `home_files` folder under one of the system-named folders, copying the template folder into it (without the `template_` prefix on the directory name), switching all files in the copy into symlinks back to the template folder, and then deciding which symlinks should be preserved in the copy.  This allows a directory tree of files to be populated with conditional per-host configuration.  
This can be automated with the `from_template.sh` tool.  

All of these folders should have a `home.file.<name>` defined in the user.nix file.  The templates should all have a `home.file.<name>` that's disabled, and once a copy is made into the per-host folder the `home.file.<name>.enable = true` should be added to the host-specific nix file.