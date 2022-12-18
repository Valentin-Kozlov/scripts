#!/usr/bin/env bash

# variables
pg_username=postgres
pg_host=127.0.0.1
pg_port=5432
backup_path="./backup_db"
export PGPASSWORD=mytest


# check root permission
if [ "$(id -u)" != 0 ]
then 
    echo "root permission required" >&2
    exit 1
fi

#check backup_path
if [ ! -d $backup_path ]
then
    mkdir $backup_path
    echo "Directory $backup_path created"
fi

#----------------------------------------------------------------------------------------------------------------------
backup_database() {
databases=$(psql -U $pg_username -h $pg_host -p $pg_port -c "SELECT datname FROM pg_database where not datistemplate;")

dbs="$(echo "${databases##*-}" | cut -d "(" -f 1)"

for db in $dbs
do 
    pg_dump -U $pg_username -h $pg_host -p $pg_port "$db" -Fc | gzip > $backup_path/"$db"_"$(date "+%d-%m-%Y")".sql.gz
done
}
#----------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------
choose_restore_database() {
# uniq list backup files
file_backup=$(ls $backup_path)
n=$(for file in $file_backup;do echo "$file" | cut -d "_" -f 1;done)
uniq_name=$(echo "$n" | sort -u )

printf "Сhoose a database to restore\n" 
select db in ${uniq_name[@]}; do
    case $db in
        "") echo 'Invalid choice' >&2 ;;
        *)  break ;;
    esac
done
printf "Your choice is %s\n" "$db"

printf "Choose a date to restore\n"
t=$(echo "$file_backup" | grep $db)
date_db=$(for i in $t;do echo $i | cut -d "_" -f 2 | cut -d "." -f 1;done)
select d in ${date_db[@]}; do
    case $d in
        "") echo 'Invalid choice' >&2 ;;
        *)  break ;;
    esac
done

file_backup_gz=$(echo "$file_backup" | grep ^"$db"_"$d")

gunzip "$backup_path/$file_backup_gz" -k
file_backup_sql=$(ls $backup_path | grep ^"$(echo "$file_backup_gz" | cut -d "." -f 1,2)"$)

pg_restore  --clean \
            --dbname="$db" \
            --host=$pg_host \
            --port=$pg_port \
            --username=$pg_username \
            --no-password \
            "$backup_path/$file_backup_sql"

rm "$backup_path/$file_backup_sql"
}
#----------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------
all_restore_database() {
file_backup=$(ls $backup_path)
n=$(for file in $file_backup;do echo "$file" | cut -d "_" -f 2 | cut -d "." -f 1;done)
uniq_date=$(echo "$n" | sort -u )

printf "Choose a date to restore\n"
select d in ${uniq_date[@]}; do
    case $d in
        "") echo 'Invalid choice' >&2 ;;
        *)  break ;;
    esac
done

selected_files=$(echo "$file_backup" | grep "$d.sql.gz$")

for file in $selected_files
do
    gunzip "$backup_path/$file" -k
    file_backup_sql=$(ls $backup_path | grep ^"$(echo "$file" | cut -d "." -f 1,2)"$)
    db=$(echo $file | cut -d "_" -f 1)

    pg_restore  --clean \
                --dbname="$db" \
                --host=$pg_host \
                --port=$pg_port \
                --username=$pg_username \
                --no-password \
                "$backup_path/$file_backup_sql"

    rm "$backup_path/$file_backup_sql"
done
}
#----------------------------------------------------------------------------------------------------------------------

select option in "Create backup" "Restore the selected database" "Restore all databases" "Stop"
do case $option in
    "Create backup") backup_database ;;
    "Restore the selected database") choose_restore_database ;;
    "Restore all databases") all_restore_database ;;
    "Stop") break ;;
    *) echo "Wrong option" >&2;;
esac
done

unset PGPASSWORD