#!/bin/bash

pool=$2
dataset=$3
IFS=',' read -r -a gpgrecipients <<< "$4"

poolset="${pool}/${dataset}"
keystorage="${HOME}/keystorage"

keyfile="${keystorage}/${pool}_${dataset}.key"

case "$1" in
        mount)
            echo "Mounting ${poolset}"
            sudo zpool import ${pool}
            gpg --decrypt ${keyfile} | sudo zfs load-key ${poolset}
            sudo zfs mount ${poolset}
            exit 0
            ;;
         
        unmount)
            echo "Un-Mounting  ${poolset}"
            sudo zfs unmount ${poolset}
            sudo zfs unload-key ${poolset}
            sync
            exit 0
            ;;

        init)
            if [ ! -d ${keystorage} ]; then
                echo "Creating missing folder ${keystorage}"
                mkdir -p ${keystorage}
            fi
            if [ -e ${keyfile} ]; then
                echo "Keyfile ${keyfile} exist. Stopping to prevent disaster!"
                exit 2
            else
                echo "Create Key and Dataset for ${poolset}"
                recipientpara=""
                for recipient in "${gpgrecipients[@]}"
                do
                    recipientpara="${recipientpara} --recipient ${recipient}"
                done
                echo "Creating random encrypted bytes"
                dd if=/dev/urandom bs=1 count=32 | gpg --symmetric --encrypt --output ${keyfile} ${recipientpara}
                sync
                gpg --list-packets ${keyfile}
                echo "Creating ZFS"
                gpg --decrypt ${keyfile} | sudo zfs create -o encryption=aes-256-ccm -o keyformat=raw ${poolset}
                exit 0
            fi
            ;;
        *)
            echo $"Usage: $0 {mount|unmount|init}"
            echo $"Parameter: <pool> <dataset> <gpg-keys>"
            exit 1
 
esac
