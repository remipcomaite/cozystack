#!/bin/sh
set -e
set -u

PROFILES="initramfs kernel iso installer"
FIRMWARES="amd-ucode amdgpu-firmware bnx2-bnx2x i915-ucode intel-ice-firmware intel-ucode qlogic-firmware"
EXTENSIONS="drbd zfs"

mkdir -p profiles

printf "fetching talos version: "
talos_version=${1:-$(skopeo --override-os linux --override-arch amd64 list-tags docker://ghcr.io/siderolabs/imager | jq -r '.Tags[]' | grep '^v[0-9]\+.[0-9]\+.[0-9]\+$' | sort -V | tail -n 1)}
echo "$talos_version"

export "TALOS_VERSION=$talos_version"

for firmware in $FIRMWARES; do
  printf "fetching %s version: " "$firmware"
  firmware_var=$(echo "$firmware" | tr '[:lower:]' '[:upper:]' | tr - _)_VERSION
  version=$(skopeo list-tags docker://ghcr.io/siderolabs/$firmware | jq -r '.Tags[]|select(length == 8)|select(startswith("20"))' | sort -V | tail -n 1)
  echo "$version"
  export "$firmware_var=$version"
done

for extension in $EXTENSIONS; do
  printf "fetching %s version: " "$extension"
  extension_var=$(echo "$extension" | tr '[:lower:]' '[:upper:]' | tr - _)_VERSION
  version=$(skopeo --override-os linux --override-arch amd64 list-tags docker://ghcr.io/siderolabs/$extension | jq -r '.Tags[]' | grep "\-${talos_version}$" | sort -V | tail -n1)
  echo "$version"
  export "$extension_var=$version"
done

for profile in $PROFILES; do
  echo "writing profile profiles/$profile.yaml"
  cat > profiles/$profile.yaml <<EOT
# this file generated by hack/gen-profiles.sh
# do not edit it
arch: amd64
platform: metal
secureboot: false
version: ${TALOS_VERSION}
input:
  kernel:
    path: /usr/install/amd64/vmlinuz
  initramfs:
    path: /usr/install/amd64/initramfs.xz
  baseInstaller:
    imageRef: ghcr.io/siderolabs/installer:${TALOS_VERSION}
  systemExtensions:
    - imageRef: ghcr.io/siderolabs/amd-ucode:${AMD_UCODE_VERSION}
    - imageRef: ghcr.io/siderolabs/amdgpu-firmware:${AMDGPU_FIRMWARE_VERSION}
    - imageRef: ghcr.io/siderolabs/bnx2-bnx2x:${BNX2_BNX2X_VERSION}
    - imageRef: ghcr.io/siderolabs/i915-ucode:${I915_UCODE_VERSION}
    - imageRef: ghcr.io/siderolabs/intel-ice-firmware:${INTEL_ICE_FIRMWARE_VERSION}
    - imageRef: ghcr.io/siderolabs/intel-ucode:${INTEL_UCODE_VERSION}
    - imageRef: ghcr.io/siderolabs/qlogic-firmware:${QLOGIC_FIRMWARE_VERSION}
    - imageRef: ghcr.io/siderolabs/drbd:${DRBD_VERSION}
    - imageRef: ghcr.io/siderolabs/zfs:${ZFS_VERSION}
output:
  kind: ${profile}
  outFormat: raw
EOT
done
