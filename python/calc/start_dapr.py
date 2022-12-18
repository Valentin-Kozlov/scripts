import csv
import requests
import json
import redis
import os
import psycopg2
from contextlib import closing
import yaml
from datetime import datetime
import subprocess
import sys


def getAnswer():
    while True:
        answer = input("Ответ: ")
        if answer != "yes" and answer != "no":
            print("Введите \"yes\" для продолжения или \"no\" для завершения скрипта")
        elif answer == "no":
            sys.exit("Вы завершили работу скрипта")
        else:
            break


def getAuthToken():
    uri = configuration["Keycloak"]["authUrl"]
    authUri = f"{uri}/protocol/openid-connect/token"
    authCreds = {
        "client_id": configuration["Keycloak"]["clientID"],
        "client_secret": configuration["Keycloak"]["clientSecret"],
        "grant_type": "client_credentials"}
    response = requests.post(authUri, data=authCreds)
    if 200 == response.status_code:
        token = response.json()["access_token"]
        return token
    else:
        return response.status_code


def redis_clear():
    if configuration["Redis"]["enable"]:
        ssl_conn = redis.Redis(
            host=configuration["Redis"]["url"],
            port=configuration["Redis"]["port"],
            ssl=configuration["Redis"]["ssl"],
            ssl_certfile=configuration["Redis"]["ssl_certfile"],
            ssl_keyfile=configuration["Redis"]["ssl_keyfile"],
            ssl_cert_reqs="required",
            ssl_ca_certs=configuration["Redis"]["ssl_ca_certs"],
        )
        keys_select = ssl_conn.keys("zif-cm*")
        for key in keys_select:
            ssl_conn.delete(key)
        keys_after = ssl_conn.keys("zif-cm*")
        if len(keys_after) == 0:
            print("Очистка Redis кэша завершена.")
    else:
        print(
            """Проведите очистку redis кэша вручную, перейдя в консоль контейнера
        введите следующую команду:
        redis-cli KEYS "zif-cm-*" | xargs redis-cli DEL
        По окончанию процедуры, подтвердите вводом \"yes\" для продолжения или \"no\"
        для завершения работы скрипта.
        """)
        getAnswer()


def connectDB(command):
    with closing(psycopg2.connect(
                 dbname=configuration["Postgres"]["dbname"],
                 user=configuration["Postgres"]["user"],
                 password=configuration["Postgres"]["password"],
                 host=configuration["Postgres"]["host"])) as conn:
        with conn.cursor() as cursor:
            cursor.execute(command)
            res = cursor.fetchall()
        return res


def runBash(path):
    run = subprocess.Popen(path,
                           stdout=subprocess.PIPE, encoding='utf-8')
    res = run.stdout.read()
    return res


# перечень таблиц для очистки расчетов
tableForCleaning = (
    'TaskExecutionStatuses',
    'RunningStreamingCalculationTasks',
    'RunningRecalculationTasksForStreamingCalculations',
    'RunningRecalculationTasksForPeriodicCalculations',
    'RunningPeriodicCalculationTasks',
    'RecalculationTasks',
    'Parameters',
    'Parameter_s',
    'Parameter_h',
    'ImportProcessData',
    'Groups',
    'ExecutionStatus_s',
    'ExecutionConfiguration_s',
    'ExecutionConfiguration_h',
    'Code_s',
    'Code_h',
    'Calculations',
    'Calculation_s',
    'Calculation_h',
    'CalculationVersions',
    'CalculationVersionMigrations',
    'CalculationTasks',
    'CalculationTask_s',
    'CalculationTask_h',
    'CalculationTaskTriggerParameterLink',
    'CalculationTaskLink',
    'CalculationParameterLink',
    'CalculationMigrations',
    'CalculationGroup_s',
    'CalculationGroup_h',
    'CalculationGroupLinks',
    'CalculationGroupLink',
    'CalculationConfigurations')

# путь до bash скриптов
bashCheckPermission = "./bash/oc_check_permission.sh"
bashScaleDown = "./bash/oc_scale_down.sh"
bashScaleUp = "./bash/oc_scale_up.sh"

# загрузка конфигурации скрипта
with open("conf.yaml", "r") as config:
    try:
        configuration = yaml.safe_load(config)
    except yaml.YAMLError as exc:
        print(exc)

# проверка прав доступа и в тот ли Openshift project произошел login
checkPermission = runBash(bashCheckPermission)
print(f"Проверка доступа к проекту Openshift: {checkPermission}")
if checkPermission != "OK":
    project = configuration["Openshift"]["project"]
    print(f"""{checkPermission}
    Проверьте подключение и права доступа к Openshift project: {project}""")
    sys.exit()

# проверка Keycloak
checkKeycloak = getAuthToken()
if checkKeycloak == 401:
    sys.exit("Проверьте правильность указанных логина и пароля в Keycloak.")
elif checkKeycloak == 404:
    sys.exit("Проверьте правильность указанного пути до Keycloak.")
else:
    print("Проверка подключения и получения ключа в Keycloak: OK")

# проверка есть ли файл содержащий ID расчетных свойств, если указано
# в файле конфигурации создание его False
file = configuration["File"]["csvFileName"]
checkFile = os.path.exists(file)
if configuration["File"]["create"] is False:
    if checkFile:
        res = "OK"
        print(f"Проверка конфигурации \"File\": {res}")
    else:
        res = "ERROR: Проверьте путь до файла и его наличие"
        print(f"Проверка конфигурации \"File\": {res}")
        sys.exit()

# sql запрос на получение id расчетных свойств из базы cm-metadata
selectCalcProperties = 'select * from (select ctl."CalculationId" from "CalculationTaskLink" ctl\
    join "CalculationTask_s" cts\
    on cts."Id" = ctl."TaskId"\
    where cts."TriggerType" in (1, 2, 4, 5) /* 1 - ListenData, 2 - ByTrigger, 4 - OnDemand, 5 - Periodic */\
    and cts."Tt" is null\
    and cts."IsDeleted" = false\
    union\
    select cv."CalculationId"\
    from "CalculationConfigurations" cc\
    join "CalculationVersions" cv\
    on cv."Id" = cc."CalculationVersionId"\
    where "CalculationConfigurationParentId" is null\
    and "TriggerType" in (1, 2, 4, 5) /* 1 - ListenData, 2 - ByTrigger, 4 - OnDemand, 5 - Periodic */\
    and cv."ActiveTo" is null) all_calculations'

# скалирование сервисов отвечающих за расчеты в 0
print("Подключение к Openshift и скалирование в 0 сервисов расчетов...")
checkDown = runBash(bashScaleDown)
if checkDown == "OK":
    print(f"Статус скалирования сервисов: {checkDown}")
else:
    print("Что-то пошло не так, проверьте подключение...")
    sys.exit()


d = datetime.now().strftime('%H-%M-%d-%m-%Y')
# получение и запись id расчетных свойств из базы cm-metadata
if configuration["File"]["create"]:
    getCalcProperties = connectDB(selectCalcProperties)
    with open(configuration["File"]["csvFileName"], mode="w", encoding='utf-8') as w_file:
        file_writer = csv.writer(w_file, delimiter=",", lineterminator="\r\n")
        for row in getCalcProperties:
            file_writer.writerow(row)
else:
    answer = input(
        "Сделать бэкап расчетных свойств в отдельный файл? \"yes\" or \"no\": ")
    if answer == "yes":
        getCalcProperties = connectDB(selectCalcProperties)
        with open(f"./backup/propertiesCalc-backup-{d}.csv", mode="w", encoding='utf-8') as w_file:
            file_writer = csv.writer(
                w_file, delimiter=",", lineterminator="\r\n")
            for row in getCalcProperties:
                file_writer.writerow(row)

# Вызов функции очистки кэша Redis
redis_clear()

# очистка базы сервиса расчетов
print(
    f"Проверьте файл с расчетными свойствами по пути: {file}. Для продолжения введите \"yes\". ")
getAnswer()
conn = psycopg2.connect(dbname=configuration["Postgres"]["dbname"],
                        user=configuration["Postgres"]["user"],
                        password=configuration["Postgres"]["password"],
                        host=configuration["Postgres"]["host"])
with conn.cursor() as cursor:
    conn.autocommit = True
    for table in tableForCleaning:
        deleteFromTables = f'delete from "{table}";'
        cursor.execute(deleteFromTables)

print("Скалируем сервисы расчетов до указанных значений в конфигурации скрипта...")
checkUp = runBash(bashScaleUp)
if checkUp == "OK":
    print(f"Статус скалирования сервисов расчетов: {checkUp}")
else:
    print(f"""Статус скалирования сервисов расчетов: {checkUp}.
    Завершите исправление и подтвердите продолжение выполнения скрипта.""")
    getAnswer()

print("Импортирование расчетных свойств...")
with open(configuration["File"]["csvFileName"]) as fileName:
    fileRead = csv.reader(fileName)
    url = configuration["Openshift"]["urlMetadata"]
    for row in fileRead:
        rowID = row[0]
        print(f"Расчетное свойство: {rowID}")
        requestText = f"{url}/v3/properties/{rowID}/import"
        data = ''
        res = requests.post(requestText, headers={
            "acept": "*/*",
            "Authorization": "Bearer " + getAuthToken()
        }, data=json.dumps(data)
        ).status_code
        print(f"Статус: {res}")
with open(configuration["File"]["csvFileName"]) as fileName:
    row_count = sum(1 for line in fileName)
print(f"""Импортирование завершено.
Было импортированно {row_count} свойства.""")
