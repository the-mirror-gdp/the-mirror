## PCKs Folder

This folder contains sources for all PCKs that are generated with The Mirror's pck_packer_tool. This is important as PCK files are mounted as layers of virtual file systems on top of original file system of The Mirror. This results in possibility of file conflicts.

Each PCK should be contained in its own folder, where it will be later "extracted" on demand during PCK loading process.

This directory is excluded from exports. This means that we can't reference files in this directory outside of generated PCKs.
