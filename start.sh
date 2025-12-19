#!/bin/bash
set -e # Exit the script if any statement returns a non-true return value

# ---------------------------------------------------------------------------- #
#                          Function Definitions                                #
# ---------------------------------------------------------------------------- #

# Start nginx service
start_nginx() {
    echo "-- Starting Nginx service --"
    service nginx start
    echo "-- Nginx service started --"
}

# Execute script if exists
execute_script() {
    local script_path=$1
    local script_msg=$2
    if [[ -f ${script_path} ]]; then
        echo "${script_msg}"
        bash ${script_path}
    fi
}

# Setup ssh
setup_ssh() {
    if [[ $PUBLIC_KEY ]]; then
        echo "-- Setting up SSH --"
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

        echo "-- SSH host keys --"
        for key in /etc/ssh/*.pub; do
            echo "Key: $key"
            ssh-keygen -lf $key
        done

        echo "-- Starting SSH service --"
        service ssh start
        echo "-- SSH service started --"
    fi
}

# Export env vars
export_env_vars() {
    echo "-- Exporting environment variables --"
    printenv | grep -E '^[A-Z_][A-Z0-9_]*=' | grep -v '^PUBLIC_KEY' | awk -F = '{ val = $0; sub(/^[^=]*=/, "", val); print "export " $1 "=\"" val "\"" }' > /etc/rp_environment
    if ! grep -q 'source /etc/rp_environment' ~/.bashrc; then
        echo 'source /etc/rp_environment' >> ~/.bashrc
    fi
}

# Start jupyter lab
start_jupyter() {
    if [[ $JUPYTER_PASSWORD ]]; then
        echo "-- Starting Jupyter Lab --"
        mkdir -p /workspace &&
            cd / &&
            nohup python3 -m jupyter lab --allow-root --no-browser --port=8888 --ip=* --FileContentsManager.delete_to_trash=False --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' --IdentityProvider.token=$JUPYTER_PASSWORD --ServerApp.allow_origin=* --ServerApp.preferred_dir=/workspace &> /jupyter.log &
        echo "-- Jupyter Lab started --"
    fi
}

# ---------------------------------------------------------------------------- #
#                           ComfyUI Specific Functions                         #
# ---------------------------------------------------------------------------- #

# Setup comfyUI server
setup_comfyui() {
    echo "-- Setting up ComfyUI --"
    cd /workspace

    # Clone or update ComfyUI repo
    if [ ! -d "ComfyUI" ]; then
        echo "-- Cloning ComfyUI --"
        git clone https://github.com/comfyanonymous/ComfyUI.git
    else
        echo "-- Updating ComfyUI --"
        cd ComfyUI && git pull && cd ..
    fi

    cd ComfyUI

    if [ -n "$DISABLE_CUSTOM" ] && [ "$DISABLE_CUSTOM" == "true" ]; then
        echo "-- Custom nodes disabled, skipping ComfyUI custom nodes setup... --"
    else
        # Clone or update ComfyUI-Manager repo
        if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
            echo "-- Cloning ComfyUI-Manager --"
            git clone https://github.com/ltdrdata/ComfyUI-Manager.git ./custom_nodes/ComfyUI-Manager
        else
            echo "-- Updating ComfyUI-Manager --"
            cd custom_nodes/ComfyUI-Manager && git pull && cd ../..
        fi

        # Clone or update RGThree-ComfyUI repo
        if [ ! -d "custom_nodes/RGThree-ComfyUI" ]; then
            echo "-- Cloning RGThree-ComfyUI --"
            git clone https://github.com/rgthree/rgthree-comfy.git ./custom_nodes/RGThree-ComfyUI
        else
            echo "-- Updating RGThree-ComfyUI --"
            cd custom_nodes/RGThree-ComfyUI && git pull && cd ../..
        fi

        # Get SeedVarianceEnhancer repo
        if [ ! -d "custom_nodes/SeedVarianceEnhancer" ]; then
            echo "-- Get SeedVarianceEnhancer --"
            wget https://civitai.com/api/download/models/2460090 -O seed_variance_enhancer.zip && \
            unzip seed_variance_enhancer.zip -d custom_nodes && \
            rm seed_variance_enhancer.zip
        else
            echo "-- Updating SeedVarianceEnhancer --"
            wget https://civitai.com/api/download/models/2460090 -O seed_variance_enhancer.zip && \
            rm -rf custom_nodes/SeedVarianceEnhancer && \
            unzip seed_variance_enhancer.zip -d custom_nodes && \
            rm seed_variance_enhancer.zip
        fi
    fi

    # Add custom ComfyUI workflows 
    mkdir -p ./user/default/workflows
    if [ ! -f "./user/default/workflows/flux_dev_example.json" ]; then
        echo "-- Get default flux workflow --"
        wget -P ./user/default/workflows/ https://github.com/matheohan/ComfyUI-Sage-Runpod/releases/download/workflow/flux_dev_example.json
    else
        echo "-- Default flux workflow already exist, skipping... --"
    fi
    if [ ! -f "./user/default/workflows/z_image_turbo_example.json" ]; then
        echo "-- Get default z-image-turbo workflow --"
        wget -P ./user/default/workflows/ https://github.com/matheohan/ComfyUI-Sage-Runpod/releases/download/workflow/z_image_turbo_example.json
    else
        echo "-- Default z-image-turbo workflow already exist, skipping... --"
    fi

    # Create model directories
    mkdir -p models/{text_encoders,diffusion_models,vae,clip,unet}

    echo "-- ComfyUI setup completed! --"
}

# Start comfyUI server
start_comfyui() {
    echo "-- Starting ComfyUI --"
    cd /workspace/ComfyUI

    if [ -n "$DISABLE_SAGE" ] && [ "$DISABLE_SAGE" == "true" ]; then
        nohup python main.py --fast fp16_accumulation --listen 0.0.0.0 &> /workspace/comfyui.log &
        echo "-- Sage Attention is disabled --"
    else
        nohup python main.py --fast fp16_accumulation --use-sage-attention --listen 0.0.0.0 &> /workspace/comfyui.log &
    fi
   
    echo "-- ComfyUI started --"
}

# Download z-image turbo models
download_z_image_turbo() {
    echo "-- Downloading z-image turbo models --"
    cd /workspace/ComfyUI

    TEMP_DIR=$(mktemp -d)
    PIDS=()
    
    # Download Text Encoder model if not exists
    if [[ ! -f "models/text_encoders/qwen_3_4b.safetensors" ]]; then
        hf download Comfy-Org/z_image_turbo \
            split_files/text_encoders/qwen_3_4b.safetensors \
            --local-dir "$TEMP_DIR" &
        PIDS+=($!)
    else
        echo "Text encoder already exists, skipping..."
    fi
    
    # Download z-image turbo model if not exists
    if [[ ! -f "models/diffusion_models/z_image_turbo_bf16.safetensors" ]]; then
        hf download Comfy-Org/z_image_turbo \
            split_files/diffusion_models/z_image_turbo_bf16.safetensors \
            --local-dir "$TEMP_DIR" &
        PIDS+=($!)
    else
        echo "Diffusion model already exists, skipping..."
    fi
    
    # Download VAE model if not exists
    if [[ ! -f "models/vae/ae.safetensors" ]]; then
        hf download Comfy-Org/z_image_turbo \
            split_files/vae/ae.safetensors \
            --local-dir "$TEMP_DIR" &
        PIDS+=($!)
    else
        echo "VAE already exists, skipping..."
    fi

    # Wait for all downloads if any
    if [[ ${#PIDS[@]} -gt 0 ]]; then
        echo "Waiting for z-image turbo downloads..."
        wait "${PIDS[@]}"
        
        # Move downloaded files to correct locations
        [[ -f "$TEMP_DIR/split_files/text_encoders/qwen_3_4b.safetensors" ]] && \
            mv "$TEMP_DIR/split_files/text_encoders/qwen_3_4b.safetensors" models/text_encoders/
        [[ -f "$TEMP_DIR/split_files/diffusion_models/z_image_turbo_bf16.safetensors" ]] && \
            mv "$TEMP_DIR/split_files/diffusion_models/z_image_turbo_bf16.safetensors" models/diffusion_models/
        [[ -f "$TEMP_DIR/split_files/vae/ae.safetensors" ]] && \
            mv "$TEMP_DIR/split_files/vae/ae.safetensors" models/vae/
    fi
    
    rm -rf "$TEMP_DIR"
    
    echo "-- z-image turbo downloads completed! --"
}

# Download flux1 dev models
download_flux1_dev() {
    echo "-- Downloading flux1 dev models --"
    cd /workspace/ComfyUI

    PIDS=()

    # Download CLIP models if not exists
    if [[ ! -f "models/clip/clip_l.safetensors" ]]; then
        hf download comfyanonymous/flux_text_encoders clip_l.safetensors --local-dir models/clip/ &
        PIDS+=($!)
    else
        echo "CLIP L already exists, skipping..."
    fi

    if [[ ! -f "models/clip/t5xxl_fp8_e4m3fn.safetensors" ]]; then
        hf download comfyanonymous/flux_text_encoders t5xxl_fp8_e4m3fn.safetensors --local-dir models/clip/ &
        PIDS+=($!)
    else
        echo "T5XXL already exists, skipping..."
    fi

    # Download Flux model if not exists
    if [[ ! -f "models/unet/flux1-dev-fp8.safetensors" ]]; then
        hf download Kijai/flux-fp8 flux1-dev-fp8.safetensors --local-dir models/unet/ &
        PIDS+=($!)
    else
        echo "Flux model already exists, skipping..."
    fi

    # Download VAE if not exists
    if [[ ! -f "models/vae/flux-vae-bf16.safetensors" ]]; then
        hf download Kijai/flux-fp8 flux-vae-bf16.safetensors --local-dir models/vae/ &
        PIDS+=($!)
    else
        echo "Flux VAE already exists, skipping..."
    fi

    # Wait for all downloads if any
    if [[ ${#PIDS[@]} -gt 0 ]]; then
        echo "Waiting for flux1 dev downloads..."
        wait "${PIDS[@]}"
    fi

    echo "-- flux1-dev downloads completed! --"
}

# Download model files based on workflow selection
download_model_files() {
    echo "-- Downloading model files in parallel --"
    cd /workspace/ComfyUI

    # Login to Hugging Face if token is provided
    if [ -n "$HF_TOKEN" ]; then
        echo "Logging into Hugging Face..."
        hf auth login --token $HF_TOKEN
    fi

    # Select workflow based on WORKFLOW environment variable
    # Default to z-image-turbo if not specified
    WORKFLOW=${WORKFLOW:-z-image-turbo}
    
    echo "Selected workflow: $WORKFLOW"

    case "$WORKFLOW" in
        z-image-turbo)
            download_z_image_turbo
            ;;
        flux1-dev)
            download_flux1_dev
            ;;
        none)
            echo "No workflow selected, skipping model downloads."
            ;;
        *)
            echo "Unknown workflow: $WORKFLOW"
            echo "Available workflows: z-image-turbo, flux1-dev, none"
            echo "Defaulting to z-image-turbo..."
            download_z_image_turbo
            ;;
    esac
    
    echo "-- All downloads completed! --"
}


# ---------------------------------------------------------------------------- #
#                               Main Program                                   #
# ---------------------------------------------------------------------------- #

start_nginx

execute_script "/pre_start.sh" "Running pre-start script..."

echo "> Pod Started <"

# Default startup
setup_ssh
start_jupyter
export_env_vars

# ComfyUI specific startup
setup_comfyui
start_comfyui
download_model_files

echo "> Start script finished, Pod is ready to use. <"

sleep infinity