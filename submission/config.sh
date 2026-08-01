#!/bin/bash
export MAX_NUM_SEQS=8
export MAX_MODEL_LEN=13312
export GPU_MEMORY_UTILIZATION=0.90
export MCQ_FORMAT_GUARD=1
export MCQ_POSTPROCESS=1
export PYTORCH_ALLOC_CONF=expandable_segments:True
export MAX_CHAT_TOKENS=2048
export CHAT_TEMPLATE=/opt/program/combined.jinja
export SPECULATIVE_CONFIG='{"method":"dflash","model":"/opt/ml/dflash-model","num_speculative_tokens":15}'
