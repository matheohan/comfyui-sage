# ComfyUI+Sage RunPod Template

Run the latest ComfyUI on RunPod with Sage.  By default, it installs all the needed models for the z-image turbo model and the default workflow.

## Access

| Port | Service |
|------|---------|
| 8188 | ComfyUI web UI |
| 8888 | JupyterLab (token via `JUPYTER_PASSWORD`, root at `/workspace`) |
| 22 | SSH (set `PUBLIC_KEY` or check logs for generated root password) |

## Pre-installed Custom Nodes

- [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)

## Directory Structure

| Path | Description |
|------|-------------|
| `/workspace/ComfyUI` | ComfyUI installation |

## Source Code

This is an open source template. Source code available at: [matheohan/comfyui-sage](https://github.com/matheohan/comfyui-sage)

## Acknowledgments

This project is based on [runpod/containers](https://github.com/runpod/containers) by RunPod, Inc. 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 