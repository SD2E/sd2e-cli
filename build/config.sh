#!/usr/bin/env bash

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
        rm -f $CONF && echo "Deleted file $CONF"
    fi

done
