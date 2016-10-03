# runcmds, The command list executor

_runcmds_ is a simple script to **sequentially** run a list of commands. This list can be define via script arguments or dedicated file.

Moreover, _runcmds_ stops from the first command execution fail, by printing the number of the failing command. In addition, _runcmds_ lets you begin the list of commands at any index.
This could be useful to re-start a failing execution flow to the failed index.

## How to use it

Beware to give you permission to execute script:

    chmod u+x runcdms.sh

Documentation and usage can be fetched from the helper message by giving the `-h` or `--help` option:

    ./runcmds.sh --help

