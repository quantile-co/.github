{ pkgs, ... }:
{
  # Useful for an operator setting up local Application Default Credentials.
  # CI authenticates through google-github-actions/auth instead.
  packages = [ pkgs.google-cloud-sdk ];
}
