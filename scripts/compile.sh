cd godot-engine
# we enable a compile database so we can easily debug in vscode and or other tools
scons target=editor optimize=speed debug_symbols=no compiledb=yes production=true