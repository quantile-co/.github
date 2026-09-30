# AI-writing detection rules

These eight narrow rules flag filler, vague praise, assistant voice, process
narration, empty hedges, stock transitions, promotional language, and templated
headings. A match is a signal for editorial review, not proof of authorship.

Patterns draw on an [AI-writing rule catalog](https://github.com/tbhb/vale-ai-tells) and
[vale-llm-slop](https://github.com/Syntaf/vale-llm-slop). The local style uses
tuned individual patterns instead of enabling either complete upstream style. Standalone
adjectives, em dashes, generic list cadence, and ordinary technical qualifiers
would flag too much legitimate engineering prose as an error. The intentionally
failing fixtures under `.vale/test/` exercise every local rule and the
error-level Google advisories. A clean fixture guards against a few false
positives.
