These scripts are for windows at the moment only, we will port them to linux/mac at some point, its trivial to do this

Copy the scripts and this directory to ../../ and make sure your engine folder and the app folder are present in that directory.

1. Put an xampp install on your pc
2. Make sure the paths match the scripts
3. Copy xampp starter contents to the xamp htdocs folder
4. Change manifest.json to the version youd like to deploy
5. Ensure the other scripts go in a folder which contains the godot-soft-fork and the mirror-godot-app
6. Run ./test-updater.sh to ensure it works
7. You can use ./package-for-updater.sh too
