# Build arguments to construct base image
ARG RUNPOD_VERSION=1.0.2
ARG CUDA_VERSION=cu1281
ARG TORCH_VERSION=torch280
ARG UBUNTU_VERSION=ubuntu2404

# Construct base image from arguments
FROM runpod/pytorch:${RUNPOD_VERSION}-${CUDA_VERSION}-${TORCH_VERSION}-${UBUNTU_VERSION}

# Re-declare ARGs to receive --build-arg values
ARG SAGE_ATTENTION_VERSION=2.2.0
ARG COMPUTE_CAP=86
ARG PYTHON_VERSION=cp311
ARG CUDA_VERSION=cu1281
ARG TORCH_VERSION=torch280

# Environment variables for start.sh
ENV SAGE_ATTENTION_VERSION=${SAGE_ATTENTION_VERSION}
ENV COMPUTE_CAP=${COMPUTE_CAP}
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV CUDA_VERSION=${CUDA_VERSION}
ENV TORCH_VERSION=${TORCH_VERSION}

# Init workspace and clone ComfyUI
WORKDIR /workspace
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /workspace/ComfyUI

# Install ComfyUI Manager
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager ./custom_nodes/comfyui-manager

# Install dependencies
RUN pip install -r requirements.txt

# Install additional dependencies
RUN pip install huggingface-hub

# Create directory for ComfyUI (-p to avoid errors if they already exist)
RUN mkdir -p models/text_encoders models/diffusion_models models/vae

# Copy start script
COPY start.sh /workspace/ComfyUI/start.sh
RUN chmod +x /workspace/ComfyUI/start.sh

# Expose ports for SSH, Jupyter, and ComfyUI
EXPOSE 22 8888 8188

# Set entrypoint to start script and CMD for additional args
ENTRYPOINT ["/workspace/ComfyUI/start.sh"]
CMD []