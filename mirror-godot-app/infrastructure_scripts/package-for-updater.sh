#!/bin/bash
set -x #echo on
cd godot-soft-fork/bin
mkdir ../../mirror-godot-app/build
./godot.windows.editor.x86_64.exe --path ../../mirror-godot-app/ --headless --export Windows ./build/TheMirror.exe
cd ../../mirror-godot-app/build
./TheMirror.exe --headless --package-build-for-server
cat version.txt
cat platform_name.txt
ver=$(cat version.txt)
platform=$(cat platform_name.txt)
echo $ver
echo $platform
deploy_path=/c/xampp/htdocs/updater/versions
mkdir ${deploy_path}/${ver}/
cp ${platform}.json ${deploy_path}/${ver}
cp ${platform}.tar.gz ${deploy_path}/${ver}/
