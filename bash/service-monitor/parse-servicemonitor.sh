#!/usr/bin/env bash

# переменные для переноса настроек
# из какого проекта..
namespace_from="test"
# в какой проект..
namespace_to="prod"
# где хранить полученные переменные для helm charts
pathForExportValue='./values-monitor'
# путь до helm chart директории
pathForChart="./chart"

# функция проверки авторизации в проекте, требуется передать название целевого проекта
check_login() {
# целевой проект
from_project=$1
echo "You need to log in to the project: $from_project"
while true;
do
# проверка проекта и прав доступа в целевом проекте
    select_project=$(oc project)
    check_permissions=$(oc auth can-i list servicemonitor)
    if [[ ($select_project == *"$from_project"*) && ( $check_permissions == "yes")]]; then
        echo "Loggin in project $from_project successfull"
        break
    else
        echo "Log in to the required project: $from_project"
        read -p "log in:" log_in
        if [[ $log_in == "oc login"* ]]; then 
            (bash -c -r "$log_in") &> /dev/null
            echo "$(oc project)"
            echo 
        elif [[ $log_in == "oc project"* ]]; then
            (bash -c -r "$log_in") &> /dev/null
        else
            echo "Wrong command, wait \"oc login\" or \"oc project\""
        fi
    fi
done
}


# функция подготовки и создания value.yaml файлов для последующего применения в helm charts
create_value_file() {
servicemonitor_all=$(oc get servicemonitor -o=custom-columns='NAME:.metadata.name')
servicemonitor_filter=$(echo "$servicemonitor_all" | grep -v 'NAME\|healthcheck-exporter-service-monitor\|prometheus\|kafka\|spark')
if [ ! -d "$pathForExportValue" ]
then
    mkdir "$pathForExportValue"
fi
for servicemonitor in $servicemonitor_filter
do
    if echo "$servicemonitor" | grep -q 'metrics' 
    then
        type="metrics"
        nameMonitor=$servicemonitor
        nameService=${servicemonitor/-metrics/}
        target=$(oc describe servicemonitor "$servicemonitor" | grep 'Path' | sed 's/    Path:      //g')
    else
        type="blackbox"
        nameMonitor="$servicemonitor"
        nameService="$servicemonitor"
        target=$(oc describe servicemonitor "$servicemonitor" | grep 'http://' | sed 's/        //g')
        blackboxtype=$(oc describe servicemonitor "$servicemonitor" | grep 'Module:' -A 1 | awk 'NR==2 {print $1}')
    fi
    export SERVICE_TYPE="$type"
    export SERVICE_NAME="$nameService"
    export SERVICE_MONITOR="$nameMonitor"
    export SERVICE_NAMESPACE="$namespace_to"
    export SERVICE_TARGET="$target"    
    export BLACKBOXTYPE="$blackboxtype"
    envsubst < value-tmpl.yaml > "$pathForExportValue/values-$servicemonitor".yaml
    blackboxtype=''
    unset SERVICE_TYPE
    unset SERVICE_NAME
    unset SERVICE_MONITOR
    unset SERVICE_NAMESPACE
    unset SERVICE_TARGET
    unset BLACKBOXTYPE
done
}

# функция развертывания helm charts в целевой кластер
apply_helm_chart(){
for servicemonitor in $servicemonitor_filter
do
    if echo "$servicemonitor" | grep -q 'metrics' 
    then
        helm upgrade --install "$servicemonitor" $pathForChart/ -f "$pathForExportValue/values-$servicemonitor.yaml"
    else
        helm upgrade --install "$servicemonitor-blackbox" $pathForChart/ -f "$pathForExportValue/values-$servicemonitor.yaml"
    fi
done
}

select option in "Prepare value.yaml and apply helm chart" "Prepare value.yaml" "Apply helm charts" "Stop"
do case $option in
    "Prepare value.yaml and apply helm chart") 
    check_login "$namespace_from"
    create_value_file
    check_login "$namespace_to"
    apply_helm_chart ;;
    "Prepare value.yaml") 
    check_login "$namespace_from"
    create_value_file 
    echo "Prepare values-*.yaml files done!"
    break ;;
    "Apply helm charts") 
    apply_helm_chart
    echo "Apply helm charts done!"
    break ;;
    "Stop") break ;;
    *) echo "Wrong option" >&2;;
esac
done