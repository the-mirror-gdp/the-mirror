#!/bin/bash
set -x #echo on
rm -rf TheMirror.exe
rm -rf /c/xampp/htdocs/updater/versions/
mkdir /c/xampp/htdocs/updater/versions/
cp -rf v1.json ./mirror-godot-app/package.json
./package-for-updater.sh
cp -rf v2.json ./mirror-godot-app/package.json
./package-for-updater.sh
cp /c/xampp/htdocs/updater/versions/3.12.72/windows.tar.gz ./
tar -xf windows.tar.gz
rm -rf windows.tar.gz
