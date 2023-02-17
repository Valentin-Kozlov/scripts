# README 
## Requirements:
Python:
- PyYAML==6.0
- requests==2.28.1




## Настройка конфигурационного файла. Описание опций.
Конфигурационный файл состоит из 3х основных секций:
- urlGrafana
- APIToken
- Path

### urlGrafana
```yaml
urlGrafana: http://grafana.com:3000
```
Секция отвечает за указания пути доступа к Grafana, указывается без закрывающего "/" в конце

### APIToken
```yaml
APIToken: eyJrIjoibDV5Wmc2NGFpMHU3ckdmclVBUG1ueEE0QU9NUHo1TDciLCJuIjoidGVzdCIsImlkIjoxMTN9
```
Секция отвечает за указания токена, по которому будут проходить обращения к Grafana API, получить ключ можно в админ панели в configuration/API Keys

### Path
```yaml
Path: ./dashboards
```
Секция отвечает за указания пути - куда необходимо загрузить выгруженные дашборды из Grafana, указывается без закрывающего "/" в конце.

## Применение
После указания конфигурационных данных в файл - запустите выполнение скрипта:
```sh
python3 getDashboards.py
```
следуйте указаниям, появляющимся в командной строке.

***That's All Folks(c)***
