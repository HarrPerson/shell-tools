#!/bin/bash
username="john"
homepath="/home/${username}"
vm_space="vm-space"
zfs_fs_name="whonix"
zfs_tempfile="${vm_space}.zfs"
whonix_import_file="${2}"

vm_gateway_name="Whonix-Gateway-XFCE"
vm_workstation_name="Whonix-Workstation-XFCE"

vm_gateway_clone_name="Live-Whonix-Gateway-XFCE"
vm_workstation_clone_name="Live-Whonix-Workstation-XFCE"

snapshot_name="init"

if [ $USER != "root" ]; then
  echo "Please be root to run this script"
  exit 1
fi

case "$1" in
  start)
    echo "starting"

    pwd_base64=$(openssl rand -base64 32)
    pwd_raw=$(echo -n ${pwd_base64} | base64 -d)
    echo "------------------------------------------------"
    echo "Tmp password: ${pwd_base64}"
    echo "------------------------------------------------"
    echo -n ${pwd_raw} | xxd
    echo "------------------------------------------------"

    echo "create file ${homepath}/${zfs_tempfile}"
    fallocate -l 32G ${homepath}/${zfs_tempfile}
    
    echo "create zpool ${vm_space}"
    zpool create ${vm_space} ${homepath}/${zfs_tempfile}

    echo "create zfs ${vm_space}/${zfs_fs_name}"
    echo -n ${pwd_raw} | zfs create -o encryption=on -o keyformat=raw ${vm_space}/${zfs_fs_name}

    chown ${username}:${username} /${vm_space}/${zfs_fs_name}

    echo "------------------------------------------------"
    zfs list
    echo "------------------------------------------------"
    zpool status
    echo "------------------------------------------------"

    sleep 1
    
    echo "clone VM"
    if mountpoint -q /${vm_space}/${zfs_fs_name}; then
      echo "clone"
        runuser -l ${username} -c "vboxmanage clonevm \"${vm_gateway_name}\" --snapshot=\"${snapshot_name}\" --name=\"${vm_gateway_clone_name}\" --basefolder=\"/${vm_space}/${zfs_fs_name}\" --options=Link --register"
        runuser -l ${username} -c "vboxmanage clonevm \"${vm_workstation_name}\" --snapshot=\"${snapshot_name}\" --name=\"${vm_workstation_clone_name}\" --basefolder=\"/${vm_space}/${zfs_fs_name}\" --options=Link --register"
    else
        echo "------------------------------------------------"
        echo "------------------------------------------------"
        echo "CREATION OF ZFS FAILED !!! ZFS not mounted?"
        echo "------------------------------------------------"
        echo "------------------------------------------------"
        exit 1
    fi
    exit 0
    ;;

  stop)
    echo "stopping"
    echo "Unmount"

    runuser -l  ${username} -c "vboxmanage unregistervm \"${vm_gateway_clone_name}\" --delete"
    runuser -l  ${username} -c "vboxmanage unregistervm \"${vm_workstation_clone_name}\" --delete"
    
    zfs unmount ${vm_space}/${zfs_fs_name}

    echo "Unload Keys and export ${vm_space}"
    dd if=/dev/urandom bs=1 count=32 2> /dev/null | zfs change-key ${vm_space}/${zfs_fs_name}
    zfs unload-key -a
    echo -n "01234567890123456789012345678901" | zfs load-key ${vm_space}/${zfs_fs_name}
    zpool export ${vm_space}
    rm -r /${vm_space}/${zfs_fs_name}

    echo "delete tempfile"
    rm ${homepath}/${zfs_tempfile}

    echo "------------------------------------------------"
    zfs list
    echo "------------------------------------------------"
    zpool status
    echo "------------------------------------------------"
    exit 0
    ;;

  *)
    echo "$0 (start|stop)"
    exit 0
    ;;
esac

exit 0


# sudo zpool import -d /home/john/vm-space.zfs vm-space
#  pwd_raw=$(echo -n "<base64 raw pwd" | base64 -d)
# echo -n ${pwd_raw} | xxd
# echo -n $pwd_raw | sudo zfs load-key vm-space/whonix
# sudo zfs mount vm-space/whonix
# sudo zfs unmount -a ; sudo zfs unload-key -a