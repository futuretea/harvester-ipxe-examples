#!/bin/bash

MYNAME=$0
ROOTDIR=$(dirname $(readlink -e $MYNAME))

USAGE="${0}: <node number>

Where:

  <node number>: node to re-install. Node number starts with zero (0). For
                 example, if you want to re-install the 3rd node, the node
                 number given should be 2.
"

if [ $# -ne 1 ] ; then
  echo "$USAGE"
  exit 1
fi

NODE_NUMBER=$1
USER_ID=$2
CLUSTER_ID=$3
NODE_NAME="harvester-${USER_ID}-${CLUSTER_ID}-${NODE_NUMBER}"

# check to make sure the node has not been created
NOT_CREATED=`vagrant status ${NODE_NAME} | grep "^${NODE_NAME}" | grep "not created" || true`

if [ "${NOT_CREATED}" == "" ] ; then
  echo "Harvester node ${NODE_NAME} already created."
  exit 1
fi

pushd $ROOTDIR
ansible-playbook ansible/reinstall_harvester_node.yml --extra-vars "@settings.yml" --extra-vars "node_number=${NODE_NUMBER}" --extra-vars "user_id=${USER_ID}" --extra-vars "cluster_id=${CLUSTER_ID}"
popd
