{ pkgs }:
pkgs.writeShellScriptBin "lefthook" ''
  # Run lefthook in a pseudo-TTY (preserves colors) and filter device attribute responses
  ${pkgs.util-linux}/bin/script -qec "${pkgs.lefthook}/bin/lefthook $*" /dev/null | ${pkgs.gnused}/bin/sed -E 's#/[0-9]+;[0-9]+c_?|/[0-9]+c_?|\\x1b\\[[?0-9;]*c##g'
  exit ''${PIPESTATUS[0]}
''
