#!/bin/bash -e

# To use this script without jetpack, re-implement
# 1) local_lsf_conf  - print the path of the local lsf.conf file
# 2) attribute_names - prints a list of attribute names
# 3) attribute_value - prints the value of an attribute given the name as the first argument
# There is also the is_blacklisted function you can edit to ignore certain attributes, like ncpus or mem.


function do_modification() {

	expr=LSF_LOCAL_RESOURCES=\"

	for attribute in $( attribute_names ); do
	    if [ $(is_blacklisted $attribute) != 0 ]; then
	        continue
	    fi;
	
	    value=$( attribute_value $attribute )
	    
	    if [ "$value" == "1" ]; then
	        value="true"
	    fi
	
	    if [ "$value" == "true" ]; then
	        expr="$expr [resource $attribute]"
	    else
	        expr="$expr [resourcemap $value*$attribute]"
	    fi
	    
	done
	
	expr="$expr\""
	
	echo sed -i s/LSF_LOCAL_RESOURCES=.*/"$expr"/g $(local_lsf_conf) >&2
	cat $(local_lsf_conf) | sed 's/LSF_LOCAL_RESOURCES=.*/'"$expr"/g > lsf.conf.tmp
	mv lsf.conf.tmp $(local_lsf_conf) 
}


function local_lsf_conf() {
	echo $(jetpack config lsf.local_etc .)/lsf.conf
}


function should_skip_script() {
	# if jetpack is installed and the user has decided to skip
	
	set +e
	which jetpack 1>&2 2>/dev/null
	set -e
	
	if [ $? == 0 ]; then
		skip_modify_local_resources=$(jetpack config lsf.skip_modify_local_resources 0)
		custom_script_uri=$(jetpack config lsf.custom_script_uri 0)
		if [ $skip_modify_local_resources != 0 ]; then
			echo skipping $0 because lsf.skip_modify_local_resources is set to $skip_modify_local_resources >&2
			echo 1
		# Note: disable this check if you want to run both scripts.
		elif [ $custom_script_uri == 0 ]; then
			echo 0
		else
			echo skipping $0 because lsf.custom_script_uri is set to $custom_script_uri. >&2
			echo 1
		fi
	else
		echo no jetpack installed, continuing >&2
		echo 0
	fi
}


function is_blacklisted() {
	# attributes we want exposed to allocate VMs but that we don't want to
	# override as a local resource
	blacklisted_attributes=("mem" "ncpus" "type" "ncores")
	
    # ex: is_blacklisted "mem"
    if [[ "${blacklisted_attributes[@]}" =~ "$1" ]]; then
        echo 1
    else
    	echo 0
    fi
}


function attribute_names() {
    # To do this without jetpack, just replace this with
    # echo key1 key2 key3
    jetpack config lsf.attribute_names
}


function attribute_value() {
    # ex: attribute_value custom_attribute
    # To do this without jetpack, just replace this with
    # your own mechanism for looking up this key / values.
    # e.g. it could just be `echo $1` if they are environment variables
    jetpack config lsf.attributes.$1
}


if [ $( should_skip_script ) == 0 ]; then
	do_modification
fi