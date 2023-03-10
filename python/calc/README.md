# README 
## Requirements:
Python:
- psycopg2-binary==2.9.5
- PyYAML==6.0
- redis==4.4.0
- requests==2.28.1
- urllib3==1.26.13
- 
Bash:
- oc==4.8.0
- yq==4.30.5



## Настройка конфигурационного файла. Описание опций.
Конфигурационный файл состоит из 5ти основных секций:
- File
- Openshift
- Keycloak
- Redis
- Postgres

### File
```yaml
File:
  create: false
  csvFileName: ./csv/file.csv
```
Секция отвечает за настройку файла с ID расчетами, которые необходимо перезапустить.

***create*** - может принимать значения **True**(создать файл конфигурации из базы расчетов) or 
**False**(взять подготовленный заранее файл расчетов, например если вам необходимо убрать часть расчетов из работы);

***csvFileName*** - директива отвечает за путь где уже создан или будет храниться файл с ID расчетов.

### Openshift
```yaml
Openshift:
  enable: true
  project: test-project
  urlMetadata: https://example.com/metadata-engine
  EngineMvel: 
    name: calc-engine
    replicas: 2
  ProviderUDL: 
    name: data-engine
    replicas: 1
  CmMetadata: 
    name: metadata-engine
    replicas: 4
```
Секция отвечает за настройку автоматического взаимодейтсвия с Openshift.

***enable*** - может принимать значения **True**(автоматический скейлинг сервисов в 0 и обратно до указанного значения, с автоматической проверкой функциональности сервисов) or **False**(в таком случае скейлинг сервисов и проверка их на работоспособность ложитсья на плечи оператора);

***project*** - имя целевого проекта в Openshift, используется для проверки в том ли полигоне залогинен оператор и есть ли права доступа для выполнения необходимых операций внутри Openshift'a; 

***urlMetadata*** - внешний роут до сервиса метадаты расчетов, необходим для импорта расчета после полной очистки, указывается без "/" в конце;

***EngineMvel,ProviderUDL,CmMetadata*** - в этих секциях указываются имена сервисов расчетов как указано на полигоне, плюс требуемое кол-во реплик для автоскейлинга, используется лишь при выставленной настройке **enable: True**

### Keycloak
```yaml
Keycloak:
  clientID: test-client
  clientSecret: Pa$$w0rd
  authUrl: https://sso.keycloak.com/auth/realms/test-project
```
Секция отвечает за настройку авторизации, для последующего вызова метода у metadata - импорт расчетных свойств. Получение токена авторизации.

***clientID*** - имя клиента в realm'e Keycloak'a с доступом до сервиса метаданных расчетов;

***clientSecret*** - пароль выбранного клиента;

***authUrl*** - url путь до reaml'a полигона.

### Redis
```yaml
Redis:
  enable: true
  url: redis-test-project.example.com
  port: 443
  ssl: true
  ssl_certfile: ./redis-crt/redis.crt
  ssl_keyfile: ./redis-crt/redis.key
  ssl_ca_certs: ./redis-crt/ca.crt
```
Секция отвечает за настройку автоматического подключения к кэшу Redis и очистке его для текущих расчетов.

***enable*** - может принимать значения **True**(автоматическое подключение и очистка текущего кэша расчетов) or **False**(в таком случае очистка кэша лежит на плечах оператора, в нужный момент скрипт выдаст оповещение о необходимости ручного вмешательства и даст рекомендации по ручной очистке кэша);

***url*** - путь до Redis;

***port*** - какой используется порт для подключения, будьте внимательны - при организации Redis кэша внутри кластера Openshift, порт при ssl подключении будет 443 или 80 - при not ssl;

***ssl*** - может принимать значения **True** or **False**, как видно из названия мы или включаем tls подключение или же нет;

***ssl_certfile,ssl_keyfile,ssl_ca_certs*** - указания пути до сертификатов Redis при настроенном tls подключении.

### Postgres
```yaml
Postgres:
  dbname: metadata-engine
  user: stolonUser
  password: $trongTestPa$$w0rd
  host: postgres01.test-project
```
Секция отвечает за настройку подключения к базе метаданных расчетов, для выполнения бэкапа(если оно требуется) и для очистки текущей информации по расчетам.

***dbname*** - имя базы данных CmMetadata;

***user*** - роль с правами доступа на чтение/изменение/удаление данных из базы CmMetadata;

***password*** - указание пароля от выбранной роли;

***host*** - путь до инстанса PostgreSQL.

## Применение
После указания конфигурационных данных в файл, подготовки окружения к запуску скрипта, входа в целевой project в Openshift - запустите выполнение скрипта:
```sh
python3 start_dapr.py
```
и следуйте указаниям появляющимся на экране, после завершения работы скрипт выдаст статистику по импортированным расчетам.

***That's All Folks(c)***
