#!/bin/bash
# This file will be sourced in init.sh
# Namespace functions with provisioning_

# https://raw.githubusercontent.com/ai-dock/stable-diffusion-webui/main/config/provisioning/default.sh

### Edit the following arrays to suit your workflow - values must be quoted and separated by newlines or spaces.
### If you specify gated models you'll need to set environment variables HF_TOKEN and/orf CIVITAI_TOKEN

DISK_GB_REQUIRED=50

APT_PACKAGES=(
    #"package-1"
    #"package-2"
)

PIP_PACKAGES=(
    #"package-1"
    #"package-2"
)

EXTENSIONS=(
    "https://github.com/Mikubill/sd-webui-controlnet"
    "https://github.com/deforum-art/sd-webui-deforum"
    "https://github.com/adieyal/sd-dynamic-prompts"
    "https://github.com/ototadana/sd-face-editor"
    "https://github.com/AlUlkesh/stable-diffusion-webui-images-browser"
    "https://github.com/Coyote-A/ultimate-upscale-for-automatic1111"
    "https://github.com/Gourieff/sd-webui-reactor"
    "https://github.com/Bing-su/adetailer"
    "https://github.com/zanllp/sd-webui-infinite-image-browsing"
    "https://github.com/hako-mikan/sd-webui-regional-prompter"
)

CHECKPOINT_MODELS=(
    # sd 1.5 models
    # https://civitai.com/models/96629/realcartoon-anime
    "https://civitai.com/api/download/models/359428"
    # https://civitai.com/models/295391/fefa-hentai-mix
    "https://civitai.com/api/download/models/331919"
    # https://civitai.com/models/136054/hardcore-hentai-13
    "https://civitai.com/api/download/models/306531"
)

LORA_MODELS=(
  # sd 1.5 loras
  # https://civitai.com/models/141942/feet-from-below-pose
  "https://civitai.com/api/download/models/157359"
  # https://civitai.com/models/171391/dd-crossed-legs-feet-focus-soles
  "https://civitai.com/api/download/models/192551"
  # https://civitai.com/models/189085?modelVersionId=212375 (Mizar's - Foot Focus Helper)
  "https://civitai.com/api/download/models/212375"
  # https://civitai.com/models/22471/lick-my-feet
  "https://civitai.com/api/download/models/48228"
)

VAE_MODELS=(
    "https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.safetensors"
    "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"
    # https://civitai.com/models/276082/vae-ft-mse-840000-ema-pruned-or-840000-or-840k-sd15-vae
    "https://civitai.com/api/download/models/311162"
    # https://civitai.com/models/23906/kl-f8-anime2-vae
    "https://civitai.com/api/download/models/28569"
)

ESRGAN_MODELS=(
    "https://huggingface.co/ai-forever/Real-ESRGAN/resolve/main/RealESRGAN_x4.pth"
    "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth"
    "https://huggingface.co/Akumetsu971/SD_Anime_Futuristic_Armor/resolve/main/4x_NMKD-Siax_200k.pth"
)

CONTROLNET_MODELS=(
)

EMBEDDINGS=(
    # https://civitai.com/models/90707/negfeet-improve-feet-quality
    "https://civitai.com/api/download/models/98441"
    # https://civitai.com/models/5224/bad-artist-negative-embedding?modelVersionId=6056 (Bad artist Negative embedding)
    "https://civitai.com/api/download/models/6056"
    # https://civitai.com/models/7808/easynegative?modelVersionId=9208 (EasyNegative)
    "https://civitai.com/api/download/models/9208"
    # https://civitai.com/models/71961/fast-negative-embedding-fastnegativev2?modelVersionId=94057 (Fast Negative Embedding (+ FastNegativeV2))
    "https://civitai.com/api/download/models/94057"
    # https://civitai.com/models/56519/negativehand-negative-embedding?modelVersionId=60938
    "https://civitai.com/api/download/models/60938"
    # https://civitai.com/models/4629/deep-negative-v1x?modelVersionId=5637
    "https://civitai.com/api/download/models/5637"
)


### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    # We need to apply some workarounds to make old builds work with the new default
    if [[ ! -d /opt/environments/python ]]; then 
        export MAMBA_BASE=true
    fi
    source /opt/ai-dock/etc/environment.sh
    source /opt/ai-dock/bin/venv-set.sh webui

    DISK_GB_AVAILABLE=$(($(df --output=avail -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_USED=$(($(df --output=used -m "${WORKSPACE}" | tail -n1) / 1000))
    DISK_GB_ALLOCATED=$(($DISK_GB_AVAILABLE + $DISK_GB_USED))
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_pip_packages
    provisioning_get_extensions
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/ckpt" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    provisioning_get_models \
        "${WORKSPACE}/storage/stable_diffusion/models/embeddings" \
        "${EMBEDDINGS[@]}"
     
    PLATFORM_ARGS=""
    if [[ $XPU_TARGET = "CPU" ]]; then
        PLATFORM_ARGS="--use-cpu all --skip-torch-cuda-test --no-half"
    fi
    PROVISIONING_ARGS="--skip-python-version-check --no-download-sd-model --do-not-download-clip --port 11404 --exit"
    ARGS_COMBINED="${PLATFORM_ARGS} $(cat /etc/forge_args.conf) ${PROVISIONING_ARGS}"
    
    # Start and exit because webui will probably require a restart
    cd /opt/stable-diffusion-webui
        source "$FORGE_VENV/bin/activate"
        LD_PRELOAD=libtcmalloc.so python launch.py \
            ${ARGS_COMBINED}
        deactivate


    provisioning_print_end
}

function pip_install() {
    "$FORGE_VENV_PIP" install --no-cache-dir "$@"
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            pip_install ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_extensions() {
    for repo in "${EXTENSIONS[@]}"; do
        dir="${repo##*/}"
        path="/opt/stable-diffusion-webui-forge/extensions/${dir}"
        if [[ -d $path ]]; then
            # Pull only if AUTO_UPDATE
            if [[ ${AUTO_UPDATE,,} == "true" ]]; then
                printf "Updating extension: %s...\n" "${repo}"
                ( cd "$path" && git pull )
            fi
        else
            printf "Downloading extension: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
        fi
    done
}

function provisioning_get_models() {
    if [[ -z $2 ]]; then return 1; fi
    dir="$1"
    mkdir -p "$dir"
    shift
    if [[ $DISK_GB_ALLOCATED -ge $DISK_GB_REQUIRED ]]; then
        arr=("$@")
    else
        printf "WARNING: Low disk space allocation - Only the first model will be downloaded!\n"
        arr=("$1")
    fi
    
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
    if [[ $DISK_GB_ALLOCATED -lt $DISK_GB_REQUIRED ]]; then
        printf "WARNING: Your allocated disk size (%sGB) is below the recommended %sGB - Some models will not be downloaded\n" "$DISK_GB_ALLOCATED" "$DISK_GB_REQUIRED"
    fi
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Web UI will start now\n\n"
}


# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
        wget --header="Authorization: Bearer $auth_token" \
             --content-disposition \
             --show-progress \
             -e dotbytes="${3:-4M}" \
             -P "$2" \
             "$1"
    elif [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$) ]]; then
        # Append the token as a query parameter to the URL for Civitai
        url_with_token="${1}?token=${CIVITAI_TOKEN}"
        wget --content-disposition \
             --show-progress \
             -e dotbytes="${3:-4M}" \
             -P "$2" \
             "$url_with_token"
    else
        wget -qnc --content-disposition \
             --show-progress \
             -e dotbytes="${3:-4M}" \
             -P "$2" \
             "$1"
    fi
}

provisioning_start
