#!/usr/bin/env bash
#
# config.sh
#
# "create" or "delete" files needed to build the source for this repo.
#

CMD=$1

if [ -z "$CMD" ];
then
    echo "Defaulting to 'create'"
    CMD="create"
fi

for CONF in VERSION requirements.txt Dockerfile CHANGELOG.md configuration.rc _config.yml CNAME
do
     if [ "$CMD" == "create" ];
     then
        if [ ! -f "$CONF" ];
        then
            cp config/sample.$CONF $CONF && echo "Created file $CONF"
        else
            echo "$CONF already exists so it wasn't over-written"
        fi
    elif [ "$CMD" == "delete" ];
    then
        if [ "$CONF" == "Dockerfile" ] || [ "$CONF" == "CNAME" ]; then
            rm -f $CONF && echo "Deleted file $CONF"    
        fi
    fi
done
