# This is an importable file for use in the flake.nix overlay definitions.
# It should be included last.
#
# This defines all Golang applications to build with CGO_ENABLLED=1.
# Golang tried to re-invent the world but got lazy when it came to libc, having only a half-assed
# libc replacement.  Anything low-level, like querying a username from a UID, is implemented badly (or how you
# explicitly shouldn't), and either works badly, or DOES NOT WORK AT ALL (i.e. username lookup of non-local/LDAP users).
# This block sets CGO_ENALED=1 as part of all golang tool builds so it actually uses the real libc implementation
# that works properly, which then necesitates including gcc as a buildInput.
self: super: {
  buildGoModule = args: 
  let
    # define an addCgo function that merges in our desired changes to the attribute set
    addCgo = origArgs: origArgs // {
      env.CGO_ENABLED = "1"; # Enables use of CGO for all golang builds
      # gcc becomes a buildInput when building with CGO
      buildInputs = (origArgs.buildInputs or []) ++ [ super.gcc ]; # Add GCC for CGO
    };
  in
    # the 'args' can be an attribute set, or a lambda function. If it's an attribute set, pass it directly
    # to the addCgo function. If it's a lambda, call it with its arguments and pass the result to the addCgo
    # function instead.
    if builtins.isAttrs args then
      super.buildGoModule (addCgo args)
    else if builtins.isFunction args then
      super.buildGoModule (a: addCgo (args a))
    else
      builtins.error "buildGoModule: 'args' isn't an attribute set or a function, so we don't know how to handle it";
}