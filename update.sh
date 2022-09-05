#!/bin/bash
script_full_path=$(dirname "$0")
cd $script_full_path || exit 1

rm -f Packages Packages.bz2 Packages.xz Packages.zst Release Release.gpg

echo "[Repository] Generating Packages..."

echo "[Repository] Creating Docker Container..."
docker run --name repo -dit -v ${PWD}:/data ubuntu

echo "[Repository] Updating Docker Container and Installing Utils..."
docker exec -it repo bash -c "(apt-get update; apt-get install apt-utils)"

docker exec -it repo bash -c "(cd data; apt-ftparchive packages ./pool > Packages)"
zstd -q -c19 Packages > Packages.zst
xz -c9 Packages > Packages.xz
bzip2 -c9 Packages > Packages.bz2

echo "[Repository] Generating Release..."
docker exec -it repo bash -c "(cd data; apt-ftparchive -o APT::FTPArchive::Release::Origin=\"Hearse's Repo\" -o APT::FTPArchive::Release::Label=\"Hearse's Repo\" -o APT::FTPArchive::Release::Suite=\"stable\" -o APT::FTPArchive::Release::Version=\"1.0\" -o APT::FTPArchive::Release::Codename=\"ios\" -o APT::FTPArchive::Release::Architectures=\"iphoneos-arm\" -o APT::FTPArchive::Release::Components=\"main\" -o APT::FTPArchive::Release::Description=\"Hearse's Dump of Tweaks\" release . > Release)"

echo "[Repository] Deleting Docker Container"
docker rm -f repo


echo "[Repository] Signing Release using Hearse's GPG Key..."
# gpg --passphrase-fd 0 -abs -u CA1E55A06D1AB4CB77DE813873A412BA64BC84B9 -o Release.gpg Release < passphrase.txt
gpg --passphrase-file passphrase.txt --pinentry-mode loopback -abs -u C8F694CD416D1C33D8C4CCFBAFFA3DC6221EBDD9 -o Release.gpg Release
echo "[Repository] Finished"

git add .
git commit -m "update"
git push
