{ pkgs, ... }:
{
  packages = [
    pkgs.vale
    pkgs.jq
  ];

  tasks."check:vale" = {
    description = "Detect AI-writing tells and enforce the pinned Google Vale style.";
    exec = ''
      set -euo pipefail
      git ls-files --cached --others --exclude-standard -z -- '*.md' | \
        xargs -0 -r vale --config .vale.ini

      # Failing fixtures verify each AI-detection category and confirm that
      # Google advisory rules really are promoted to error severity.
      if result=$(vale --config .vale.ini --output JSON .vale/test/violations.txt 2>&1); then
        echo 'Vale detection fixture unexpectedly passed.' >&2
        exit 1
      fi
      for rule in Quantile.Filler Quantile.VaguePraise Quantile.AssistantVoice \
        Quantile.ProcessNarration Quantile.EmptyHedges Quantile.StockTransitions \
        Quantile.MarketingLanguage Google.Contractions Google.Semicolons; do
        if ! jq -e --arg rule "$rule" \
          'any(.[][]; .Check == $rule and .Severity == "error")' <<< "$result" >/dev/null; then
          printf 'Vale fixture did not produce error-level %s:\n%s\n' "$rule" "$result" >&2
          exit 1
        fi
      done

      # Feed Markdown through stdin so the intentionally bad heading does not
      # enter the ordinary Markdown file scan.
      if result=$(vale --config .vale.ini --ext=.md --output JSON < .vale/test/headings.txt 2>&1); then
        echo 'Vale heading fixture unexpectedly passed.' >&2
        exit 1
      fi
      if ! jq -e \
        'any(.[][]; .Check == "Quantile.TemplatedHeadings" and .Severity == "error")' \
        <<< "$result" >/dev/null; then
        printf 'Vale heading rule did not report an error:\n%s\n' "$result" >&2
        exit 1
      fi
      vale --config .vale.ini .vale/test/clean.txt
    '';
  };
}
