# Naming, comments and formatting

Load when naming things, writing or trimming comments, or reviewing a diff for style.

## Naming

- Follow the convention already in the file. Consistency inside a project beats any external
  style guide, and a second convention is worse than an imperfect first one.
- A name states what the entity is or does, at the abstraction level of its scope. A short name
  is fine in a short scope. A long-lived entity earns a descriptive name.
- Never encode the type in the name. The type is in the declaration and in the tooling.
- Name a function for its effect (`normalize`, `find_first_gap`), a predicate for its question
  (`is_valid`, `has_capacity`), and a variable for its meaning, not its mechanism.
- Avoid abbreviations except the ones the domain already uses. Never invent one.
- Never start an identifier with an underscore, and never use a double underscore anywhere.
  Those names are reserved.
- Never name anything after a person, a ticket, or an experiment.
- Rename in a commit of its own, never mixed with a behaviour change.

## Comments

A comment states what the code cannot:

- an invariant or a precondition the types do not express;
- a unit, a coordinate convention, a layout assumption;
- a constraint imposed from outside, such as a file format, a protocol, a hardware erratum or a
  standard's wording;
- a non-obvious reason for a choice that looks wrong at first reading;
- a reference to the specification or the paper that defines the algorithm.

Do not write:

- a restatement of the code (`// increment i`);
- archaeology: "was X, now Y", "formerly", "replaces the old", "this subsumes";
- a changelog, a commit reference, an author, or a date;
- measurement receipts: benchmark numbers, machine names, campaign labels;
- a derivation essay, or a record of an approach that failed;
- commented-out code, which version control already holds;
- a `TODO` without an owner and a condition for removal.

Everything in the second list belongs in the commit message, the issue tracker or the project's
engineering notes, not in the source.

Additional rules:

- A comment that must be updated when the code changes will not be. Prefer a name, a type or an
  assertion that cannot go stale.
- If a function needs section comments, split it into functions whose names are the comments.
- Document the interface in the header at the level of the contract: what it needs, what it
  guarantees, what it may throw, who owns what. Never repeat the implementation there.
- An ASCII diagram of a layout or a dataflow is worth many sentences and rarely goes stale.
- Write in the third person about the code: "the kernel normalizes the input", not "we
  normalize" and not "I added".

## Formatting

- Formatting belongs to a `.clang-format` file applied automatically, ideally by a pre-commit
  hook. Once the file exists, formatting is not a review topic.
- Never reformat a file you are not otherwise changing, and never reformat a whole file as part
  of a change. The real diff disappears.
- Braces on every block, even a single statement.
- One declaration per line, with an initializer at first use.
- Keep lines within the project's limit. A line that needs horizontal scrolling hides its
  right-hand side.
- Blank lines separate steps inside a function. Many groups mean the function is too long.

## Diffs and review

- One logical change per commit, with a message that says what changed and why. The diff shows
  the what, never the why.
- Mechanical changes (rename, reformat, move) go in their own commits.
- A diff that touches many files for one behaviour change needs a reason stated in the message.
- Review the diff before asking anyone else to. Look for the unrelated hunk, the leftover debug
  output, the stray formatting change.
