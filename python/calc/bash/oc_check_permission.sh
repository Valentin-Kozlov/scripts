#!/usr/bin/env bash

conf="./conf.yaml"
selectProject=$(yq '.Openshift.project' < $conf)
currentProject=$(oc project | awk '{print $3}' | sed 's/"//g')
countCheck=0
if [ "$selectProject" != "$currentProject" ]; then
    echo -n "ERROR: Login and select in the rigth project: $selectProject"
    exit
else
    countCheck=$((countCheck + 1))
fi

checkPermission=$(oc auth can-i get deployment)
if [ "$checkPermission" == "no" ]; then
    echo -n "ERROR: Permission deny, check your permission"
    exit
else
    countCheck=$((countCheck + 1))
fi

if [ $countCheck == 2 ];then
    echo -n "OK"
fi