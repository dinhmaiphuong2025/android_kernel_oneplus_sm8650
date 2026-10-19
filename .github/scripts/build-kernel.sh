#!/usr/bin/env bash
set -euo pipefail

KERNEL_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
CLANG_DIR="${2:-${KERNEL_DIR}/clang}"
DEVICE="${3:-caihong}"
MSM_ARCH="${4:-pineapple}"
CUSTOM_KERNEL_NAME="${CUSTOM_KERNEL_NAME:-}"

export ARCH=arm64
export LLVM=1
export PATH="${CLANG_DIR}/bin:${PATH}"

cd "${KERNEL_DIR}"

DEFCONFIGS=(arch/arm64/configs/gki_defconfig)
if [ -f "arch/arm64/configs/vendor/${MSM_ARCH}_GKI.config" ]; then
    DEFCONFIGS+=("arch/arm64/configs/vendor/${MSM_ARCH}_GKI.config")
fi
if [ -f "arch/arm64/configs/vendor/oplus/${MSM_ARCH}_GKI.config" ]; then
    DEFCONFIGS+=("arch/arm64/configs/vendor/oplus/${MSM_ARCH}_GKI.config")
fi
if [ -f "arch/arm64/configs/vendor/${DEVICE}_GKI.config" ]; then
    DEFCONFIGS+=("arch/arm64/configs/vendor/${DEVICE}_GKI.config")
fi

mkdir -p out
KCONFIG_CONFIG="${KERNEL_DIR}/out/.config" \
    scripts/kconfig/merge_config.sh -m -r "${DEFCONFIGS[@]}"

printf '\n' >> out/.config
./scripts/config --file out/.config -e KSU -e KSU_SUSFS
./scripts/config --file out/.config -e LTO_CLANG_THIN -d LTO_CLANG_FULL

# Custom kernel name
if [ -n "${CUSTOM_KERNEL_NAME}" ]; then
    CLEAN_VERSION=$(echo "${CUSTOM_KERNEL_NAME}" | sed -E 's/^[0-9]+\.[0-9]+\.[0-9]+//')
    [[ "${CLEAN_VERSION}" != -* ]] && CLEAN_VERSION="-${CLEAN_VERSION}"
    echo "Setting custom kernel name: ${CLEAN_VERSION}"
    sed -i "\$s|echo \"\$res\"|echo \"${CLEAN_VERSION}\"|" ./scripts/setlocalversion 2>/dev/null || true
    ./scripts/config --file out/.config --set-str LOCALVERSION "${CLEAN_VERSION}"
    ./scripts/config --file out/.config -d LOCALVERSION_AUTO
fi

make O=out olddefconfig

make O=out -j"$(nproc)" Image

IMAGE_PATH="out/arch/arm64/boot/Image"
echo "=========================================="
echo "Kernel Image built successfully!"
ls -lh "${IMAGE_PATH}"
stat -c "Image exact size: %s bytes" "${IMAGE_PATH}"
echo "Stock boot.img kernel size: 35576320 bytes (~33.93 MB)"
echo "=========================================="
