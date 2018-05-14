#!/bin/bash
#
# tacclab groups

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh
source ${DIR}/cli-common.sh
source ${DIR}/tacclab-common.sh
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

function usage() {

cat <<EOF
${ITME}
Usage: ${ITME} [OPTIONS] [COMMAND]


Manage TACC.cloud Gitlab groups.

Options:
    -h,--help - Show usage information

Commands:
    list      - List available groups


EOF

}

case "$1" in
    -h|--help|help) usage; safe_exit ;;
    list) shift;
        bash $DIR/tacclab-groups-list.sh "$@";;
    version) version; safe_exit ;;
    license) terms; safe_exit ;;
    *)
        usage; safe_exit ;;
esac

