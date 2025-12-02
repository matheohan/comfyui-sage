#!/bin/bash
set -e # Exit the script if any statement returns a non-true return value

COMFYUI_DIR="/workspace/ComfyUI"
VENV_DIR="$COMFYUI_DIR/.venv"

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                  #
# ---------------------------------------------------------------------------- #

# Setup SSH with optional key or random password
setup_ssh() {
    mkdir -p ~/.ssh
    
    # Generate host keys if they don't exist
    for type in rsa dsa ecdsa ed25519; do
        if [ ! -f "/etc/ssh/ssh_host_${type}_key" ]; then
            ssh-keygen -t ${type} -f "/etc/ssh/ssh_host_${type}_key" -q -N ''
            echo "${type^^} key fingerprint:"
            ssh-keygen -lf "/etc/ssh/ssh_host_${type}_key.pub"
        fi
    done

    # If PUBLIC_KEY is provided, use it
    if [[ $PUBLIC_KEY ]]; then
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh
    else
        # Generate random password if no public key
        RANDOM_PASS=$(openssl rand -base64 12)
        echo "root:${RANDOM_PASS}" | chpasswd
        echo "Generated random SSH password for root: ${RANDOM_PASS}"
    fi

    # Configure SSH to preserve environment variables
    echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

    # Start SSH service
    /usr/sbin/sshd
}

# Export environment variables
export_env_vars() {
    echo "Exporting environment variables..."
    
    # Create environment files
    ENV_FILE="/etc/environment"
    PAM_ENV_FILE="/etc/security/pam_env.conf"
    SSH_ENV_DIR="/root/.ssh/environment"
    
    # Backup original files
    cp "$ENV_FILE" "${ENV_FILE}.bak" 2>/dev/null || true
    cp "$PAM_ENV_FILE" "${PAM_ENV_FILE}.bak" 2>/dev/null || true
    
    # Clear files
    > "$ENV_FILE"
    > "$PAM_ENV_FILE"
    mkdir -p /root/.ssh
    > "$SSH_ENV_DIR"
    
    # Export to multiple locations for maximum compatibility
    printenv | grep -E '^RUNPOD_|^PATH=|^_=|^CUDA|^LD_LIBRARY_PATH|^PYTHONPATH' | while read -r line; do
        # Get variable name and value
        name=$(echo "$line" | cut -d= -f1)
        value=$(echo "$line" | cut -d= -f2-)
        
        # Add to /etc/environment (system-wide)
        echo "$name=\"$value\"" >> "$ENV_FILE"
        
        # Add to PAM environment
        echo "$name DEFAULT=\"$value\"" >> "$PAM_ENV_FILE"
        
        # Add to SSH environment file
        echo "$name=\"$value\"" >> "$SSH_ENV_DIR"
        
        # Add to current shell
        echo "export $name=\"$value\"" >> /etc/rp_environment
    done
    
    # Add sourcing to shell startup files
    echo 'source /etc/rp_environment' >> ~/.bashrc
    echo 'source /etc/rp_environment' >> /etc/bash.bashrc
    
    # Set permissions
    chmod 644 "$ENV_FILE" "$PAM_ENV_FILE"
    chmod 600 "$SSH_ENV_DIR"
}

# Start Jupyter Lab server for remote access
start_jupyter() {
    mkdir -p /workspace
    echo "Starting Jupyter Lab on port 8888..."
    nohup jupyter lab \
        --allow-root \
        --no-browser \
        --port=8888 \
        --ip=0.0.0.0 \
        --FileContentsManager.delete_to_trash=False \
        --FileContentsManager.preferred_dir=/workspace \
        --ServerApp.root_dir=/workspace \
        --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' \
        --IdentityProvider.token="${JUPYTER_PASSWORD:-}" \
        --ServerApp.allow_origin=* &> /jupyter.log &
    echo "Jupyter Lab started"
}

# ---------------------------------------------------------------------------- #
#                           ComfyUI Specific Functions                         #
# ---------------------------------------------------------------------------- #

# Install SageAttention wheel
install_sageattention() {
    echo "Installing SageAttention wheel..."
    pip install https://github.com/matheohan/comfyui-sage/releases/download/latest/sageattention-${SAGE_ATTENTION_VERSION}+${CUDA_VERSION}${TORCH_VERSION}cc${COMPUTE_CAP}-${PYTHON_VERSION}-${PYTHON_VERSION}-linux_x86_64.whl
    echo "SageAttention installed"
}

# Start comfyUI server
start_comfyui() {
    echo "Starting ComfyUI..."
    nohup python main.py --fast fp16_accumulation --listen 0.0.0.0 --port 8080 &> /comfyui.log &
    echo "ComfyUI started"
}

# Download model files in parallel
download_model_files() {
    echo "-- Downloading model files in parallel --"
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
}


# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

echo "Pod Started"

setup_ssh
export_env_vars
start_jupyter

install_sageattention
start_comfyui
download_model_files

echo "Start script(s) finished, Pod is ready to use."

tail -f /workspace/comfyui.log
