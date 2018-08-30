#!/bin/bash
#
# tacclab keys

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# source ${DIR}/common.sh
source ${DIR}/cli-common.sh
source ${DIR}/tacclab-common.sh
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

function usage() {

cat <<EOF
${ITME}
Usage: ${ITME} [OPTIONS] [COMMAND]

Manage SSH keys on the TACC.cloud Gitlab service.

Options:
    -h,--help - Show usage information

Commands:
    list      - List available SSH keys
    add       - Add a new SSH key to your account
    remove    - Remove a key from your account

EOF

}

case "$1" in
    -h|--help|help) usage; safe_exit ;;
    list) shift;
        bash $DIR/tacclab-keys-list.sh "$@";;
    add) shift;
        bash $DIR/tacclab-keys-add.sh "$@";;
    remove) shift;
        bash $DIR/tacclab-keys-remove.sh "$@";;
    version) version; safe_exit ;;
    license) terms; safe_exit ;;
    *)
        usage; safe_exit ;;
esac

