#!/usr/bin/env bash

conf="./conf.yaml"
metadataName=$(yq '.Openshift.CmMetadata.name' < $conf)
metadataCount=$(yq '.Openshift.CmMetadata.replicas' < $conf)
mvelName=$(yq '.Openshift.EngineMvel.name' < $conf)
mvelCount=$(yq '.Openshift.EngineMvel.replicas' < $conf)
providerUdlName=$(yq '.Openshift.ProviderUDL.name' < $conf)
providerUdlCount=$(yq '.Openshift.ProviderUDL.replicas' < $conf)


scaleUP() {
nameDeployment=$1
replicasDeployment=$2
oc scale deployment "$nameDeployment" --replicas "$replicasDeployment" > /dev/null
while true;
do
    targetCount=$(oc get pod -l "zyfra.com/module=calc" | grep "$nameDeployment" | awk '{split($2,a,"/"); sum+=a[2];} END {print sum}')
    currentCount=$(oc get pod -l "zyfra.com/module=calc" | grep "$nameDeployment" | awk '{split($2,a,"/"); sum+=a[1];} END {print sum}')
    if [ "$currentCount" == "$targetCount" ];then
        break
    fi
done
}

scaleUP "$mvelName" "$mvelCount"
scaleUP "$providerUdlName" "$providerUdlCount"
scaleUP "$metadataName" "$metadataCount"

sleep 15

checkTargetCount=$(oc get deployment -l "zyfra.com/module=calc" | grep "$metadataName\|$mvelName\|$providerUdlName"| awk '{split($2,a,"/"); sum+=a[2];} END {print sum}')
checkCurrentCount=$(oc get deployment -l "zyfra.com/module=calc" | grep "$metadataName\|$mvelName\|$providerUdlName"| awk '{split($2,a,"/"); sum+=a[1];} END {print sum}')

if [ "$checkCurrentCount" == "$checkTargetCount" ];then
    echo -n "OK"
else
    echo -n "ERROR: Требуется ручное вмешательство, проблема с сервисами"
fi