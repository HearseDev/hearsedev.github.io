#!/bin/bash
script_full_path=$(dirname "$0")
cd $script_full_path || exit 1

rm Packages Packages.bz2 Packages.xz Packages.zst Release Release.gpg

echo "[Repository] Generating Packages..."
apt-ftparchive packages ./pool > Packages
zstd -q -c19 Packages > Packages.zst
xz -c9 Packages > Packages.xz
bzip2 -c9 Packages > Packages.bz2

echo "[Repository] Generating Release..."
apt-ftparchive \
        -o APT::FTPArchive::Release::Origin="Hearse's Repo" \
        -o APT::FTPArchive::Release::Label="Hearse's Repo" \
        -o APT::FTPArchive::Release::Suite="stable" \
        -o APT::FTPArchive::Release::Version="1.0" \
        -o APT::FTPArchive::Release::Codename="ios" \
        -o APT::FTPArchive::Release::Architectures="iphoneos-arm" \
        -o APT::FTPArchive::Release::Components="main" \
        -o APT::FTPArchive::Release::Description="Hearse's Dump of Tweaks" \
        release . > Release

echo "[Repository] Signing Release using Hearse's GPG Key..."
gpg -abs -u CA1E55A06D1AB4CB77DE813873A412BA64BC84B9 -o Release.gpg Release

echo "[Repository] Finished"
