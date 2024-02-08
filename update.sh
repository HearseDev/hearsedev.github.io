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
apt-ftparchive packages ./pool > Packages

zstd -q -c19 Packages >Packages.zst
xz -c9 Packages >Packages.xz
bzip2 -c9 Packages >Packages.bz2

echo "[Repository] Generating Release..."
apt-ftparchive \
		-o APT::FTPArchive::Release::Origin="Hearse's Repo" \
		-o APT::FTPArchive::Release::Label="Hearse" \
		-o APT::FTPArchive::Release::Suite="stable" \
		-o APT::FTPArchive::Release::Version="2.0" \
		-o APT::FTPArchive::Release::Codename="ios" \
		-o APT::FTPArchive::Release::Architectures="iphoneos-arm iphoneos-arm64" \
		-o APT::FTPArchive::Release::Components="main" \
		-o APT::FTPArchive::Release::Description="Hearse's Dump of Tweaks" \
		release . > Release
echo "[Repository] Signing Release using Hearse's GPG Key..."
# gpg --passphrase-fd 0 -abs -u CA1E55A06D1AB4CB77DE813873A412BA64BC84B9 -o Release.gpg Release < passphrase.txt
gpg --passphrase-file passphrase.txt --pinentry-mode loopback -abs -u 7F33B352AB8C52031DF9F319AEE471C6270B1B6B -o Release.gpg Release
echo "[Repository] Finished"

echo "[Repository] Pushing upstream"
git add .
git commit -m "update"
git gc
git push
