# ComfyUI+SageAttention RunPod Template

Run the latest ComfyUI on RunPod with SageAttention. By default, it installs all the needed models for the z-image turbo model.

## Requirements

- **Minimum CUDA Version: 12.8**

When selecting a pod on RunPod, make sure to filter by **CUDA version 12.8 or above**. You can do this by using the "CUDA versions" filter dropdown and selecting `12.8` or higher.

## Access

| Port | Service |
|------|---------|
| 8188 | ComfyUI web UI |
| 8888 | JupyterLab (token via `JUPYTER_PASSWORD`, root at `/workspace`) |
| 22 | SSH (set `PUBLIC_KEY` or check logs for generated root password) |

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WORKFLOW` | Model workflow to download at startup. Options: `z-image-turbo`, `flux1-dev`, `z-image(*)`, `none` | `z-image-turbo` |
| `DISABLE_SAGE` | Set to `true` to disable SageAttention and run ComfyUI without it | false |
| `DISABLE_CUSTOM` | Set to `true` to disable installation of default custom nodes | false |
| `HF_TOKEN` | Hugging Face token for authenticated downloads (not required for `z-image-turbo` or `flux1-dev` workflows, but can be provided for gated models) | - |
| `JUPYTER_PASSWORD` | Password/token for JupyterLab access | - |
| `PUBLIC_KEY` | SSH public key for authentication | - |

(*) Currently z-image doesn't work with SageAttention so make sure to set `DISABLE_SAGE` to `true`!

## Pre-installed Custom Nodes

- [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
- [RGThree-ComfyUI](https://github.com/rgthree/rgthree-comfy)
- [SeedVarianceEnhancer](https://civitai.com/models/2184867)

## Default Workflows

Three example workflows are pre-installed and ready to use:

| Workflow | File |
|----------|------|
| Flux Dev | `flux_dev_example.json` |
| Z-Image Turbo | `z_image_turbo_example.json` |
| Z-Image | `z_image_example.json` |

These workflows are located in `/workspace/ComfyUI/user/default/workflows/` and will appear in the ComfyUI workflow browser.

## Directory Structure

| Path | Description |
|------|-------------|
| `/workspace/ComfyUI` | ComfyUI installation |
| `/workspace/comfyui.log` | ComfyUI log file |

## Support This Project

If you like my work and don't have a RunPod account yet, feel free to use my referral link when signing up! Both you and I will receive a (minimum) **$5 credit bonus** when you add your first $10. This helps me build more wheels and improve compatibility for different GPU architectures.

[**Sign up on RunPod and get $5 credit**](https://runpod.io?ref=iu7x7ufv)

## Source Code

This is an open source template. Source code available at: [matheohan/comfyui-sage](https://github.com/matheohan/comfyui-sage)

## Acknowledgments

This project is based on [runpod/containers](https://github.com/runpod/containers) by RunPod, Inc. 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.