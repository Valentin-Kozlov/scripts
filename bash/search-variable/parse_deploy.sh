#!/usr/bin/env bash

searchVar="test"
deployments=$(oc get deployment  | awk '{print $1}')


for deploy in $deployments
do
    res=$(oc get deployment "$deploy" -o=yaml | grep "$searchVar" -A1)
    if [ -n "$res" ]; then
        echo "------------------" >> res.txt
        echo $deploy >> res.txt
        echo " " >> res.txt
        echo "$res" >> res.txt
        echo "------------------" >> res.txt
    fi
done