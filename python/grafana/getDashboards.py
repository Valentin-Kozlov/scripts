import requests
import yaml
import json
import sys

def getDashboardsList(urlGrafana, token):
    requestAllDashboards = f"{urlGrafana}/api/search/?query\=\&"
    resGrafanaList = json.loads(requests.get(requestAllDashboards, headers={
                                        "Authorization": f"Bearer {token}"
                                        }
                                ).text)
    return resGrafanaList


def getDashboardJSON(urlGrafana, token, dictDash, path):
    uidDash = dictDash["uid"]
    nameDashboards = dictDash["title"]
    if "/" in nameDashboards:
        nameDashboards = nameDashboards.replace("/", "-")
    elif " " in nameDashboards:
        nameDashboards = nameDashboards.replace(" ", "-")
    getDashboardJSON = f"{urlGrafana}/api/dashboards/uid/{uidDash}"
    jsonFileDashboards = f"{path}/{nameDashboards}.json"
    resDashboardsJSON = requests.get(getDashboardJSON, headers={
                                        "Authorization": f"Bearer {token}"
                                        }
                                )
    f = open(jsonFileDashboards, 'w', encoding='utf-8')
    f.write(json.dumps(resDashboardsJSON.json()["dashboard"], indent=4, ensure_ascii=False))
    f.close()
    return print(f"{nameDashboards} - экпорт завершен!")


def getAnswer():
    while True:
        print("Введите \"yes\" для продолжения или \"no\" для завершения скрипта")
        answer = input("Ответ:").encode("utf-8")
        if answer != "yes" and answer != "no":
            print("Некорректный ответ! Введите \"yes\" для продолжения или \"no\" для завершения скрипта")
        elif answer == "no":
            sys.exit("Вы завершили работу скрипта")
        else:
            break


with open("conf.yaml", "r") as config:
    try:
        configuration = yaml.safe_load(config)
    except yaml.YAMLError as exc:
        print(exc)

urlGrafana = configuration["urlGrafana"]
token = configuration["APIToken"]
path = configuration["Path"]

listDashboards = getDashboardsList(urlGrafana, token)
countDashboards = len(listDashboards)
print(f"Будет экспортированно {countDashboards} dashboards.")
getAnswer()

for dash in listDashboards:
    getDashboardJSON(urlGrafana, token, dash, path)
