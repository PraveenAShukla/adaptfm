# What we tried

Most of the images we built are public on
[Docker Hub](https://hub.docker.com/r/11noel11/adaptfm-submission/tags). The ranked entry
and the dual-backend build are not among them; both were exported and uploaded as
tarballs rather than pushed. The configurations below were read back out of the images
that are there, so anyone can check them without pulling 20 GB:

```bash
REPO=11noel11/adaptfm-submission; TAG=dflash-r6
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$REPO:pull" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')
CFG=$(curl -s -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  "https://registry-1.docker.io/v2/$REPO/manifests/$TAG" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["config"]["digest"])')
curl -sL -H "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/$REPO/blobs/$CFG" \
  | python3 -c 'import sys,json;[print(e) for e in json.load(sys.stdin)["config"]["Env"]]'
```

## The three phases

| When | Tags | What was actually configured |
| --- | --- | --- |
| 18-20 May | `dflash-r4-cudagraph` | DFlash, 8 draft tokens |
| 18-20 May | `dflash-r6`, `-r6v5`, `-r6v7`, `-r6v9` | DFlash, 20 draft tokens |
| 23-30 May | `smartfinal-ngram`, `ngram-clean`, `superfix`, `patchfix`, `finalwinner`, `bake_base`, `ngram_sm86_fix`, `clean_v1`, `clean_v4_native` | n-gram prompt lookup, 20 or 40 draft tokens |
| 2-11 June | `clean_suffix128`, `suffix_v3`-`v16`, `single_*`, `nss1_12k`, `ns64_v1`, `ns64_quality_fixed`, `ns64_answer_soon`, `ns48_answer_soon_safe` | suffix decoding, 128 draft tokens |

We started with a trained drafter, spent a week on n-gram lookup, moved to suffix decoding
for the speed, and came back to DFlash when suffix could not clear the quality gate. The
ranked entry uses `K=15` and is not among the tags above; its closest published relatives
are the `dflash-r6` images, same configuration at 20 draft tokens.

## Two tags that prove a point

`dflash-r6v2` and `dflash-r6v12` are both named for DFlash. Neither contains a DFlash
configuration. Both are n-gram, at 20 and 40 draft tokens.

We reused tag names across rebuilds and by the end could not tell from a tag what was in
an image. Name images after the configuration, or record the digest when you build.

## What did not work, and why

**n-gram lookup, roughly ten days.** Drafts by copying spans from the prompt: excellent on
repetitive input, poor on generated text. Around 13.8× at depth 40 on the A10G, but
startup cost climbed with depth (150 s at 40, 355 s at 80) and deeper bought nothing.

**Suffix decoding, roughly two weeks.** Fast enough to lead on latency and never able to
pass quality within the rules. Rejected drafts corrupt the recurrent state, generation
runs away, and the runaways blow the 60-second per-sample limit. The full account is in
[submission-history.md](submission-history.md).

**Larger draft windows.** Our suffix configuration proposed 64 tokens over a tree 128 deep
and lost to DFlash at 15. Not a clean comparison — we changed the algorithm at the same
time — so it says nothing about the best `K` for either. It does show that rejected draft
tokens still cost drafting and verification time.

**Flattened images.** `docker export | docker import` got us under the 20 GB limit and
broke the entrypoint, so several submissions never started. Prefer a normal build from a
smaller base.

**Recompute on accept.** The obvious fix for recurrent-state handling under speculation.
It ran out of memory on a 24 GB card.

## The one that got away

The dual-backend build passed quality and reached second overall, first among entries that
passed, before it was removed as benchmark routing. Getting the same behaviour out of one
backend cost us the rest of the competition and about three quarters of the speed.
