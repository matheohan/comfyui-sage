# Build arguments
ARG RUNPOD_VERSION=1.0.2
ARG CUDA_VERSION=cu1281
ARG TORCH_VERSION=torch280
ARG UBUNTU_VERSION=ubuntu2404

# =============================================================================
# Builder stage - clone repos and extract requirements
# =============================================================================
FROM alpine/git AS builder

WORKDIR /build

# Clone repos to extract requirements
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git && \
    git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git

# =============================================================================
# Final stage - install dependencies
# =============================================================================
FROM runpod/pytorch:${RUNPOD_VERSION}-${CUDA_VERSION}-${TORCH_VERSION}-${UBUNTU_VERSION}

# Re-declare ARGs
ARG SAGE_ATTENTION_VERSION=2.2.0
ARG CUDA_VERSION=cu1281
ARG TORCH_VERSION=torch280
ARG COMPUTE_CAP=86
ARG PYTHON_VERSION=cp312

WORKDIR /tmp

# Copy only requirements files from builder
COPY --from=builder /build/ComfyUI/requirements.txt /tmp/comfyui-requirements.txt
COPY --from=builder /build/ComfyUI-Manager/requirements.txt /tmp/manager-requirements.txt

# Install all dependencies
RUN pip --no-cache-dir install -r comfyui-requirements.txt && \
    pip --no-cache-dir install -r manager-requirements.txt && \
    pip --no-cache-dir install huggingface-hub && \
    pip --no-cache-dir install https://github.com/matheohan/comfyui-sage/releases/download/latest/sageattention-${SAGE_ATTENTION_VERSION}+${CUDA_VERSION}${TORCH_VERSION}cc${COMPUTE_CAP}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl && \
    rm -rf /tmp/*.txt /root/.cache/pip

# Copy start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose ports for SSH, Jupyter, and ComfyUI
EXPOSE 22 8888 8188

# Set default command to run start script
CMD ["/start.sh"]