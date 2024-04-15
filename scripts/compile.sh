cd godot-engine
# we enable a compile database so we can easily debug in vscode and or other tools
# scons target=editor optimize=speed debug_symbols=no compiledb=yes production=true

# export ANDROID_HOME=/home/gordon/Android/Sdk
export ANDROID_HOME=/Users/gordon/Library/Android/sdk
#scons platform=android target=template_release arch=arm32
scons target=editor
scons platform=android ndk_platform=android-24 target=template_release arch=arm64 verbose=yes
cd platform/android/java
# On Linux and macOS
./gradlew generateGodotTemplates