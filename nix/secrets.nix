{ config, ... }:
{
  # Force SecretSpec to resolve the selected profile during Devenv evaluation:
  # missing required deployment inputs then block shell and task entry.
  # Never assign the resolved values to Nix `env`: doing so writes credentials
  # into a world-readable Nix store shell file. The env provider's variables
  # already pass through to the child shell without this extra mapping.
  enterShell = builtins.deepSeq config.secretspec.secrets "";
}
