# initialise all submodules
git submodule update --init --recursive
# ensure the latest version of all submodules are provided (legacy git support)
# in some older versions of Git, if you use the --init option, already-initialized submodules may not be updated. In that case, you should also run the command without --init option.
# reference: https://stackoverflow.com/questions/10168449/git-update-submodules-recursively
git submodule update --recursive