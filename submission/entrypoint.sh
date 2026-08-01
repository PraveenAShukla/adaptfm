#!/usr/bin/env bash
set -euo pipefail

# Load per-mode config overrides
[ -f /opt/program/config.sh ] && source /opt/program/config.sh


set -euo pipefail

echo "engine=vllm"
echo "model=${MODEL_ID:-unset}"
echo "tokenizer=${TOKENIZER_ID:-unset}"
echo "quantization=${QUANTIZATION:-auto}"
echo "kv_cache_dtype=${KV_CACHE_DTYPE:-auto}"
echo "speculative_config=${SPECULATIVE_CONFIG:-none}"
echo "max_model_len=${MAX_MODEL_LEN:-unset}"
echo "gpu_memory_utilization=${GPU_MEMORY_UTILIZATION:-unset}"
nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader || true

python3 /opt/program/serve_vllm_contest.py
