
# Inputs

If the snapshot of Nixpkgs defines different versions of the same package for different platforms (Linux vs. OSX) the package set might differ between them,
which might seem like it is not reproducible. This is very unlikely though, and it still applies that time should not play a role in the build process.

TODO other reasons why the output of `ghc-pkg` might be differ from the one in [README.md](./README.md)?

