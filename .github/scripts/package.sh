#!/usr/bin/env bash
set -euo pipefail

KERNEL_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DEVICE="${DEVICE:-caihong}"
MSM_ARCH="${MSM_ARCH:-pineapple}"
CUSTOM_KERNEL_NAME="${CUSTOM_KERNEL_NAME:-}"
BOOT_IMG_URL="${BOOT_IMG_URL:-}"
ANYKERNEL_REPO="${ANYKERNEL_REPO:-https://github.com/coolzyd9107/AnyKernel3.git}"
ANYKERNEL_BRANCH="${ANYKERNEL_BRANCH:-master}"

DIST_DIR="${KERNEL_DIR}/dist"
mkdir -p "${DIST_DIR}"

IMAGE_PATH="${KERNEL_DIR}/out/arch/arm64/boot/Image"
if [ ! -f "${IMAGE_PATH}" ]; then
    echo "Error: Image not found at ${IMAGE_PATH}"
    exit 1
fi

cp "${IMAGE_PATH}" "${DIST_DIR}/Image"
cp "${KERNEL_DIR}/out/.config" "${DIST_DIR}/config"

# Print comparison with stock
BUILT_SIZE=$(stat -c "%s" "${IMAGE_PATH}")
STOCK_SIZE=35576320
DIFF_BYTES=$((BUILT_SIZE - STOCK_SIZE))

echo "=========================================="
echo "Artifact Size Summary:"
echo "Built Image: ${BUILT_SIZE} bytes ($(awk "BEGIN {printf \"%.2f\", ${BUILT_SIZE}/1048576}") MB)"
echo "Stock Image: ${STOCK_SIZE} bytes ($(awk "BEGIN {printf \"%.2f\", ${STOCK_SIZE}/1048576}") MB)"
echo "Difference:  ${DIFF_BYTES} bytes"
echo "=========================================="

# ==================== Package AnyKernel3 ====================
echo "Packaging AnyKernel3 zip..."
ANYKERNEL_DIR="${KERNEL_DIR}/AnyKernel3"
rm -rf "${ANYKERNEL_DIR}"
git clone --depth 1 -b "${ANYKERNEL_BRANCH}" "${ANYKERNEL_REPO}" "${ANYKERNEL_DIR}"
rm -rf "${ANYKERNEL_DIR}/.git"

cp "${IMAGE_PATH}" "${ANYKERNEL_DIR}/Image"

KERNEL_TAG="BakaSU-SuSFS"
if [ -n "${CUSTOM_KERNEL_NAME}" ]; then
    CLEAN_NAME="${CUSTOM_KERNEL_NAME#-}"
    KERNEL_TAG="${CLEAN_NAME}"
fi

sed -i "s/^kernel.string=.*/kernel.string=${KERNEL_TAG} Kernel for ${DEVICE} (${MSM_ARCH})/" "${ANYKERNEL_DIR}/anykernel.sh"

ZIP_NAME="AnyKernel3-${DEVICE}-${MSM_ARCH}-${KERNEL_TAG}.zip"
(
    cd "${ANYKERNEL_DIR}"
    zip -r9 "${DIST_DIR}/${ZIP_NAME}" ./* -x "README.MD" -x "LICENSE"
)
rm -rf "${ANYKERNEL_DIR}"
echo "AnyKernel3 package created at ${DIST_DIR}/${ZIP_NAME}"

# ==================== Patch boot.img if requested ====================
if [ -n "${BOOT_IMG_URL}" ]; then
    echo "Downloading stock boot image from ${BOOT_IMG_URL}..."
    curl -sL --fail -o "${DIST_DIR}/stock-boot.img" "${BOOT_IMG_URL}"
    echo "Downloading ksud for boot-patch..."
    curl -sL --fail -o "${DIST_DIR}/ksud" \
        "https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.0/ksud-x86_64-unknown-linux-musl"
    chmod +x "${DIST_DIR}/ksud"
    echo "Patching boot image with built kernel..."
    "${DIST_DIR}/ksud" boot-patch \
        --boot "${DIST_DIR}/stock-boot.img" \
        --kernel "${IMAGE_PATH}" \
        --out "${DIST_DIR}" \
        --out-name BakaSU-boot.img
    rm -f "${DIST_DIR}/stock-boot.img" "${DIST_DIR}/ksud"
    echo "BakaSU-boot.img created successfully."
fi
