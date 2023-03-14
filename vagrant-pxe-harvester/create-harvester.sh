#!/usr/bin/env bash
[[ -n $DEBUG ]] && set -x
set -eou pipefail

usage() {
    cat <<HELP
USAGE:
    create-harvester.sh harvester_url harvester_version node_number user_id cluster_id cpu_count memory_size disk_size
    create-harvester.sh https://releases.rancher.com/harvester master 2 1 1 8 16384 150G
HELP
}

exit_err() {
    echo >&2 "${1}"
    exit 1
}

if [ $# -lt 8 ]; then
    usage
    exit 1
fi

harvester_url=$1
harvester_version=$2
node_number=$3
user_id=$4
cluster_id=$5
cpu_count=$6
memory_size=$7
disk_size=$8

# destroy
mkdir -p /mnt/harvester-deploy
cd /mnt/harvester-deploy
if [ -d "${user_id}-${cluster_id}/harvester-ipxe-examples" ];then
    pushd ${user_id}-${cluster_id}/harvester-ipxe-examples/vagrant-pxe-harvester
    vagrant destroy -f
    rm -rf .vagrant
    set +e
    virsh net-destroy harvester-${user_id}-${cluster_id}
    set -e
    popd
    rm -rf ${user_id}-${cluster_id}/harvester-ipxe-examples
fi
mkdir -p ${user_id}-${cluster_id}
cd ${user_id}-${cluster_id}
git clone -b futuretea https://github.com/futuretea/harvester-ipxe-examples
cd harvester-ipxe-examples/vagrant-pxe-harvester

# up
cp settings.yml settings.yml.bak
jinja2 settings.yml.j2 \
    -D harvester_url=${harvester_url} \
    -D harvester_version=${harvester_version} \
    -D node_number=${node_number} \
    -D user_id=${user_id} \
    -D cluster_id=${cluster_id} \
    -D cpu_count=${cpu_count} \
    -D memory_size=${memory_size} \
    -D disk_size=${disk_size} >settings.yml

bash -x ./setup_harvester.sh
vagrant status

# proxy
docker rm -f harvester-${user_id}-${cluster_id}-proxy
host_ip=$(ip a show $(ip route show default | awk '{print $5}') | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
host_port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
docker run -d --name harvester-${user_id}-${cluster_id}-proxy --restart=unless-stopped --net=host alpine/socat tcp-l:${host_port},reuseaddr,fork tcp:10.${user_id}.${cluster_id}.10:443
echo "harvester mgmt url: https://${host_ip}:${host_port}"

