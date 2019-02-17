#!/bin/bash
set -e


BUCKET_ADDR=s3://$1
LOCAL_FOLDER=${2:-.}


display_help() {
    echo "Usage: $0 bucket_name [local_folder]" >&2
    # echo some stuff here for the -a or --add-options 
    exit 1
}

case "$1" in
      help | --help | -h)
        display_help
      ;;
esac

BUCKET_EXISTS=$(aws s3api head-bucket --bucket "$1" 2> /dev/null ; echo $?)

# BUCKET_EXISTS=$(aws s3api wait bucket-exists --bucket "$1")

if [ $BUCKET_EXISTS -ne 0 ]; then
    read -p "Bucket doesn't exist. Create bucket? [y/N]: " CREATE_BUCKET

    if [ "$CREATE_BUCKET" = y ] || [ "$CREATE_BUCKET" = Y ] ; then
        aws s3api create-bucket --bucket $1 > /dev/null
        aws s3api put-bucket-versioning --bucket $1 --versioning-configuration MFADelete="Disabled",Status="Enabled"
        read -p "Time in days after last update to transferring to Glacier (0 to disable): " DAYS
        if [ $DAYS ] ; then
            CONF_FILENAME=/tmp/$(uuidgen).json
            RULE_CONF='{
                    "Rules": [{
                        "Status": "Enabled",
                        "Filter": {
                           "Prefix": ""
                        },
                        "NoncurrentVersionTransitions": [
                            {
                                "NoncurrentDays": '"$DAYS"',
                                "StorageClass": "GLACIER"
                            }
                        ],
                        "Transitions": [
                            {
                                "Days": '"$DAYS"',
                                "StorageClass": "GLACIER"
                            }
                        ],
                        "ID": "MainRule"
                    }]
                }'
            echo $RULE_CONF > $CONF_FILENAME
            
            aws s3api put-bucket-lifecycle-configuration  \
                --bucket $1  \
                --lifecycle-configuration file://$CONF_FILENAME 
        fi

    
    else
        exit 1
    fi 
fi




echo "Starting watch"
while true; do
    aws s3 sync --delete $LOCAL_FOLDER $BUCKET_ADDR
    inotifywait $LOCAL_FOLDER &> /dev/null
done;