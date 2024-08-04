#!/usr/bin/env bash
set -euo pipefail

export ARCH="${ARCH-x86-64}"
SCRIPTFOLDER="$(dirname "$(readlink -f "$0")")"

if [ $# -lt 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0 VERSION SYSEXTNAME"
  echo "The script will download the kata-containers binary (e.g., for 3.7.0) and create a sysext squashfs image with the name SYSEXTNAME.raw in the current folder."
  echo "A temporary directory named SYSEXTNAME in the current folder will be created and deleted again."
  echo "All files in the sysext image will be owned by root."
  echo "To use arm64 pass 'ARCH=arm64' as environment variable (current value is '${ARCH}')."
  "${SCRIPTFOLDER}"/bake.sh --help
  exit 1
fi

VERSION="$1"
SYSEXTNAME="$2"

# The github release uses different arch identifiers, we map them here
# and rely on bake.sh to map them back to what systemd expects
if [ "${ARCH}" = "amd64" ] || [ "${ARCH}" = "x86-64" ]; then
  URL="https://github.com/kata-containers/kata-containers/releases/download/${VERSION}/kata-static-${VERSION}-amd64.tar.xz"
elif [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ]; then
  URL="https://github.com/kata-containers/kata-containers/releases/download/${VERSION}/kata-static-${VERSION}-arm64.tar.xz"
fi

rm -rf "${SYSEXTNAME}"
mkdir -p "${SYSEXTNAME}" && cd "$_"
wget -q -O kata.tar.xz ${URL}
tar -xf kata.tar.xz
rm kata.tar.xz

# Create the links that are created by tools/packaging/kata-deploy/scripts/kata-deploy.sh
# in function configure_different_shims_base() so the kata-runtime can be located.
# TODO: Let it be created by kata-deploy
mkdir -p "usr/local/bin" && cd "$_"
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-clh-v2
ln -sf /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 containerd-shim-kata-cloud-hypervisor-v2
ln -sf /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 containerd-shim-kata-dragonball-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-fc-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-coco-dev-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-nvidia-gpu-snp-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-nvidia-gpu-tdx-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-nvidia-gpu-v2
ln -sf /opt/kata/runtime-rs/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-runtime-rs-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-sev-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-snp-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-tdx-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-qemu-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-stratovirt-v2
ln -sf /opt/kata/bin/containerd-shim-kata-v2 containerd-shim-kata-v2
ln -sf /opt/kata/bin/kata-runtime kata-runtime

RELOAD=1 "${SCRIPTFOLDER}"/bake.sh "${SYSEXTNAME}"
rm -rf "${SCRIPTFOLDER}/${SYSEXTNAME}"
rm -rf "${SCRIPTFOLDER}/kata-containers"
