# About the reference files

These Dockerfiles were reconstructed from the HPC workspace. They document
the software stack and intended submission layout, but they are not presented
as the exact final image.

The submission Dockerfile expects two files that are not included yet:

- `serve_vllm_contest.py`
- `entrypoint.sh`

Noel should add the exact versions from the MacBook before this directory is
treated as a reproducible submission. We should then compare the Dockerfile
with the final build history and record the image name, digest, and submission
ID.
