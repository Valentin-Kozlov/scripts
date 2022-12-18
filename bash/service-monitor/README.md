# README

Данный скрипт позволяет оператору перенести настройки service-monitor с одного полигона на другой.
В целом функционал скрипта хорошо расписан в его теле, с подробными комметариями.
Всё что нужно прописать в настройках скрипта находится в следующих полях:
```sh
# переменные для переноса настроек
# из какого проекта..
namespace_from="test"
# в какой проект..
namespace_to="prod"
# где хранить полученные переменные для helm charts
pathForExportValue='./values-monitor'
# путь до helm chart директории service-monitor
pathForChart="./chart"
```
При запуске скрипта дается выбор:
```sh
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
```
**"Prepare value.yaml and apply helm chart"** - запускает парсинг конфигураций service-monitor, вычитывает их в директорию и применяет на целевой полигон вычитанные настройки, полный цикл скрипта;
**"Prepare value.yaml"** - запускает лишь парсинг конфигураций service-monitor и вычитывает их в директорию, дает возможность русного вмешательства - оценить правильно ли собранны конфигурации и поправить их в случае чего;
**"Apply helm charts"** - применяет конфигурации из директории указанной в pathForExportValue и запускает helm upgrade --install;

***That's All Folks(c)***