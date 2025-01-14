#!/bin/bash
set -e

function ensure_installed() {
  if ! [ -x "$(command -v $1)" ]; then
    echo "Error: $1 is not installed." >&2
    exit 1
  fi
}
function is_installed() {
  if ! [ -x "$(command -v $1)" ]; then
    return 1
  fi
  return 0
}

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Detected Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Detected macOS"
  # Check if apt-ftparchive is installed
  if ! is_installed apt-ftparchive; then
    echo "Installing apt-ftparchive"
    ensure_installed curl
    ensure_installed brew
    sudo curl -L -O --output-dir /usr/local/bin https://apt.procurs.us/apt-ftparchive && sudo chmod +x /usr/local/bin/apt-ftparchive
    echo "Installed apt-ftparchive"
  fi
fi
ensure_installed apt-ftparchive
ensure_installed zstd
ensure_installed xz
ensure_installed bzip2
ensure_installed gpg
ensure_installed git

script_full_path=$(dirname "$0")
cd $script_full_path || exit 1

echo "[Repository] Cleaning..."
rm -f Packages Packages.bz2 Packages.xz Packages.zst Release Release.gpg

echo "[Repository] Generating Packages..."
apt-ftparchive packages ./pool >Packages

zstd -q -c19 Packages >Packages.zst
xz -c9 Packages >Packages.xz
bzip2 -c9 Packages >Packages.bz2

echo "[Repository] Generating Release..."
apt-ftparchive release -c ./repo.conf . >Release

echo "[Repository] Signing Release using Hearse's GPG Key..."
# gpg --passphrase-file passphrase.txt --pinentry-mode loopback -abs -u  -o Release.gpg Release
gpg -abs -u 9A74C5143C033D0641011CE6108E251A767E4AAE -o Release.gpg Release

echo "[Repository] Finished"

echo "[Repository] Pushing upstream"
git add .
git commit -m "update"
git gc
git push

# CydiaIcon.png 64x64
# CydiaIcon@2x.png 128 x 128
# CydiaIcon@3x.png 192 x 192
