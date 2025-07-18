# export sshd_config file contents based on SSHD -T
dsc config export -f sshd_config.yaml

# get the registry settings for SSHD's Default Shell
dsc config get -f default_shell.yaml

# set the registry settings for SSHD's Default Shell to pwsh
dsc config set -f .\default_shell.yaml
