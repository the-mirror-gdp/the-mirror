cd godot-engine
# we enable a compile database so we can easily debug in vscode and or other tools
# scons target=editor optimize=speed debug_symbols=no compiledb=yes production=true

export ANDROID_HOME=/home/gordon/Android/Sdk
scons platform=android target=template_release arch=arm32
scons platform=android target=template_release arch=arm64
