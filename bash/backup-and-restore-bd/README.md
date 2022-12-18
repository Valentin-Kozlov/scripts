# README
Данный скрипт позволяет выполнить бэкап всех текущих баз и при необходимости восстановить все или лишь выбранные базы с выбранной датой.
Основные конфигурации находятся здесь:
```sh
# variables
pg_username=postgres
pg_host=127.0.0.1
pg_port=5432
backup_path="./backup_db"
export PGPASSWORD=mytest
```
Как понятно из названий переменных, мы указываем имя роли из под которой будем проводить манипуляции с бд, имя хоста, порт, путь где будут расположены бэкапы и пароль для доступа к бд.

При запуске скрипта даётся выбор действия:
```sh
select option in "Create backup" "Restore the selected database" "Restore all databases" "Stop"
do case $option in
    "Create backup") backup_database ;;
    "Restore the selected database") choose_restore_database ;;
    "Restore all databases") all_restore_database ;;
    "Stop") break ;;
    *) echo "Wrong option" >&2;;
esac
done
```
**"Create backup"** - как понятно из названия запустится процедура вычитки списка баз в выбранном инстансе и будет выполнен бэкап;

**"Restore the selected database"** - позвоялет сделать выбор какую из баз следует восстановить и на какую дату выбрать бэкап;

**"Restore all databases"** - позвоялет сделать выбор даты бэкапов и произвести восстановление всех баз.

***That's All Folks(c)***