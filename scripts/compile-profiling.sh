cd godot-engine
# we enable a compile database so we can easily debug in vscode and or other tools
scons target=editor optimize=speed_trace debug_symbols=yes compiledb=yes tracy_enable=yes