#!/bin/bash
set -e

node_template=$(jetpack config cyclecloud.node.template)
if [ "$node_template" != "master" ]; then
	exit 0
fi;

lsf_top=$(jetpack config lsf.lsf_top)
set +e
source $lsf_top/conf/profile.lsf
set -e

if [ "$LSF_ENVDIR" == "" ]; then
	echo please define LSF_ENVDIR
	exit 1
fi

if [ "$LSF_SERVERDIR" == "" ]; then
	echo please define LSF_SERVERDIR
	exit 1
fi

rc_scripts_dir=$LSF_SERVERDIR/../../resource_connector/azurecc/scripts

rm -rf $rc_scripts_dir
mkdir -p $rc_scripts_dir

cp $CYCLECLOUD_SPEC_PATH/files/host_provider/*.sh $rc_scripts_dir/
chmod +x $rc_scripts_dir/*.sh

mkdir -p $rc_scripts_dir/src
cp $CYCLECLOUD_SPEC_PATH/files/host_provider/src/*.py $rc_scripts_dir/src/
mkdir -p $LSF_ENVDIR/resource_connector/azurecc/
export PYTHONPATH=$rc_scripts_dir/src:$PYTHONPATH
/opt/cycle/jetpack/system/embedded/bin/python -m add_resource_connector

set +e
# for jetpack log access
usermod -a -G cyclecloud lsfadmin
set -e

lsadmin limstartup
lsadmin resstartup
badmin hstartup
lsadmin reconfig -f

sleep 10
# usually requires 5-15 seconds after lasadmin reconfig
for attempt in $( seq 1 6); do
	echo attempting 'badmin mbdrestart -f' $attempt/6
	(badmin mbdrestart -f || sleep 10) && exit 0
done
# could not restart badmin
exit 1