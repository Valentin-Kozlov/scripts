#!/usr/bin/env bash

conf="./conf.yaml"
metadata=$(yq '.Openshift.CmMetadata.name' < $conf)
mvel=$(yq '.Openshift.EngineMvel.name' < $conf)
providerUdl=$(yq '.Openshift.ProviderUDL.name' < $conf)

oc scale deployment "$metadata" --replicas 0 > /dev/null
oc scale deployment "$mvel" --replicas 0 > /dev/null
oc scale deployment "$providerUdl" --replicas 0 > /dev/null

while true;
do 
    checkPods=$(oc get pod -l "zyfra.com/module=calc" | grep "$metadata\|$mvel\|$providerUdl" | wc -l)
    if [[ "$checkPods" == 0 ]];then
       echo -n -e "OK"
       exit
    fi
done