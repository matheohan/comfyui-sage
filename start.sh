#!/bin/bash
echo -- Installing SageAttention wheel --
pip install https://github.com/matheohan/comfyui-sage/releases/download/latest/sageattention-${SAGE_ATTENTION_VERSION}+${CUDA_VERSION}${TORCH_VERSION}cc${COMPUTE_CAP}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl

echo -- Start comfyUI --
python main.py --fast fp16_accumulation --use-sage-attention --listen 0.0.0.0 &

echo -- Downloading model files in parallel --
# Login to Hugging Face if token is provided
if [ -n "$HF_TOKEN" ]; then
    echo "Logging into Hugging Face..."
    huggingface-cli login --token $HF_TOKEN
fi

# Start all downloads in parallel using huggingface-hub
echo "Starting text encoder downloads..."
huggingface-cli download split_files/text_encoders/qwen_3_4b.safetensors --local-dir models/text_encoders/ &

echo "Starting model download..."
huggingface-cli download split_files/diffusion_models/z_image_turbo_bf16.safetensors --local-dir models/diffusion_models/ &

echo "Starting VAE download..."
huggingface-cli download split_files/vae/ae.safetensors --local-dir models/vae/ &

echo "All downloads completed!"