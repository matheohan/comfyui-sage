#!/bin/bash
set -e # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

# Start nginx service
start_nginx() {
    echo "Starting Nginx service..."
    service nginx start
}

# Setup ssh
setup_ssh() {
    if [[ $PUBLIC_KEY ]]; then
        echo "Setting up SSH..."
        mkdir -p ~/.ssh
        echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
        chmod 700 -R ~/.ssh

        if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
            ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -q -N ''
            echo "RSA key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_rsa_key.pub
        fi

        if [ ! -f /etc/ssh/ssh_host_dsa_key ]; then
            ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -q -N ''
            echo "DSA key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_dsa_key.pub
        fi

        if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
            ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -q -N ''
            echo "ECDSA key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_ecdsa_key.pub
        fi

        if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
            ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -q -N ''
            echo "ED25519 key fingerprint:"
            ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
        fi

        service ssh start

        echo "SSH host keys:"
        for key in /etc/ssh/*.pub; do
            echo "Key: $key"
            ssh-keygen -lf $key
        done
    fi
}

# Export env vars
export_env_vars() {
    echo "Exporting environment variables..."
    printenv | grep -E '^[A-Z_][A-Z0-9_]*=' | grep -v '^PUBLIC_KEY' | awk -F = '{ val = $0; sub(/^[^=]*=/, "", val); print "export " $1 "=\"" val "\"" }' > /etc/rp_environment
    if ! grep -q 'source /etc/rp_environment' ~/.bashrc; then
        echo 'source /etc/rp_environment' >> ~/.bashrc
    fi
}

# Start jupyter lab
start_jupyter() {
    if [[ $JUPYTER_PASSWORD ]]; then
        echo "Starting Jupyter Lab..."
        mkdir -p /workspace &&
            cd / &&
            nohup python3 -m jupyter lab --allow-root --no-browser --port=8888 --ip=* --FileContentsManager.delete_to_trash=False --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' --IdentityProvider.token=$JUPYTER_PASSWORD --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace &> /jupyter.log &
        echo "Jupyter Lab started"
    fi
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

# Start comfyUI
start_comfyui() {
    echo "Starting ComfyUI..."
    nohup python3 main.py --fast fp16_accumulation --listen 0.0.0.0 --port 8080 &> /comfyui.log &
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

start_nginx

echo "Pod Started"

setup_ssh
start_jupyter

install_sageattention
start_comfyui
download_model_files

export_env_vars

echo "Start script(s) finished, Pod is ready to use."

sleep infinity
