# What we are working on next

These are open questions, not results. Nothing below has been measured well enough to
claim. We are writing them down because the competition pointed at them and we would
rather work in the open.

Qwen3.5-4B is a hybrid model: most layers are Gated DeltaNet, a linear-attention
recurrence that keeps a fixed-size running state, and the rest are full attention. That
architecture is becoming common, and much of the tooling around it still assumes a
transformer. Three of the four directions below come from that gap.

## Recurrent state under low precision

While fitting the model into 24 GB we noticed the recurrent state seemed far less
bothered by lost precision than the KV cache was. There is a plausible reason. A KV
cache stores every past token and reads all of it back, so quantization error
accumulates and nothing removes it. A gated recurrence multiplies its state by a forget
gate below one at every step, which shrinks whatever is already in the state, including
error introduced earlier.

If that holds, the recurrent state should tolerate coarser quantization than the KV
cache at matched accuracy, and the gap should widen with context length. The obvious
failure mode is a forget gate sitting close to one, where there is little shrinking to
do. We have not tested it.

## What sets a hybrid model's usable context

A transformer can attend to any earlier token directly. A recurrent layer cannot, so
what it can still use from far back depends on how quickly its state decays and how much
that state holds, rather than on the length it was trained at.

That suggests usable context might be predictable from published configuration values,
the steady-state forget gate and the state dimension, across model families. We would
like to know whether a simple relationship holds or whether it is messier than that.

## Exploring several continuations at once

The chunked scans behind linear attention are associative, which is not true of
attention over a growing KV cache. That property might allow several independent
continuations to be advanced in one memory-bound kernel rather than one at a time, which
would matter for tree-shaped speculation, constrained decoding, and sampling several
candidates.

As far as we have seen, current practice for these models is to draft in a single chain,
because tree verification costs more than the extra acceptance returns. Whether the
associative route changes that arithmetic is a kernel question, and it is cheap to
answer: measure whether a chunked scan at batch B×K costs meaningfully less than K times
a scan at batch B. If it scales linearly, there is nothing here.

## Getting the artifact to start

Around 176 teams entered this competition and 43 landed a scored submission. Some of
that gap is teams who ran out of time, and some is artifacts that did not start. Ours
were in the second group. Serving benchmarks measure throughput and latency on the
assumption that the server comes up, and here that assumption decided the ranking.

We are interested in what a useful check looks like: something that exercises cold
start, memory pressure, and mismatched kernel builds against the artifact you are about
to ship, rather than against the image you built it from. Much of this is ordinary
engineering discipline. We did not have it, and it cost us the result.

## Getting in touch

If you are working on any of this, or you think one of these is already answered, please
open an issue. We would rather hear it early.
