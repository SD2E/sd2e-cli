#!/bin/bash
#
# tacclab projectss

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/cli-common.sh
source ${DIR}/tacclab-common.sh
ITME=$(basename $0)
ITME=${ITME%.sh}
ITME=${ITME//[-]/ }

function usage() {

cat <<EOF
${ITME}
Usage: ${ITME} [OPTIONS] [COMMAND]

Manage TACC.cloud Gitlab projects

Options:
    -h,--help - Show usage information

Commands:
    list      - List projects for the current user
    create    - Create a new project
    delete    - Delete a project

EOF

}

case "$1" in
    -h|--help|help) usage; safe_exit ;;
    list) shift;
        bash $DIR/tacclab-projects-list.sh "$@";;
    create) shift;
        bash $DIR/tacclab-projects-create.sh "$@";;
    delete) shift;
        bash $DIR/tacclab-projects-delete.sh "$@";;
    version) version; safe_exit ;;
    license) terms; safe_exit ;;
    *)
        usage; safe_exit ;;
esac

