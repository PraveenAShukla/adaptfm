# Contributing

This started as a competition writeup. The parts we would most like help with are the
open questions in [docs/future-work.md](docs/future-work.md), none of which we have
measured properly yet.

## What is useful

**Telling us something is already answered.** If one of the questions in future-work.md
has a paper behind it, or a result that settles it, open an issue with the reference. A
question we can close is worth more to us than one we spend a month on.

**Telling us we are wrong.** Several claims here rest on our own logs from a competition
we ran under time pressure. If a number looks wrong, please say so.

**Reproducing something.** The build steps are in [docs/method.md](docs/method.md) and
the images we published can be inspected without downloading them, as shown in
[docs/what-we-tried.md](docs/what-we-tried.md). Different hardware is especially useful.
Our numbers are from one A10G and we would not assume they transfer.

## If you want to work on one of the open questions

Open an issue first and say which one. We would rather collaborate than duplicate, and
if we have already started on it we will say so.

## The standard we are trying to hold

Everything in this repository should be one of three things, and marked as which:

- a number we measured, with the conditions it was measured under
- a number from the official results, cited to them
- a question we have not answered

Where we could not tell which, we said so rather than guessing. We would ask the same of
a contribution. A pull request that reports a speedup should say what hardware, what
prompt shapes, how many runs, and what the quality check was. A claim without those is
not something either of us can check.

## Practical notes

- No model weights, no container archives. The repository stays small.
- No credentials, tokens, upload URLs, or private host names, including in logs.
- If you add a result, add the command that produced it.
