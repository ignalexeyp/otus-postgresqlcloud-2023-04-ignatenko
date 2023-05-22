# Бэкапы Постгреса

# Цель:
  Используем современные решения для бэкапов
  Делам бэкап Постгреса используя WAL-G или pg_probackup и восстанавливаемся на другом кластере


### Развернуть Постгрес на ВМ

  Создал виртуальную машину в ЯО

    yc compute instance create --name postgreshw5 --hostname postgreshw5 --cores 2 --memory 4 --create-boot-disk size=40G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2004-lts --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --zone ru-central1-a --metadata-from-file ssh-keys=C:\Users\AlexeyI\alexeyi.txt

  Подключился через MobaXterm
  Поставил на нее PostgreSQL 15

    sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15 htop iotop atop unzip pgtop lynx iftop

  Скачал бинарник wal-g

    wget https://github.com/wal-g/wal-g/releases/download/v2.0.1/wal-g-pg-ubuntu-20.04-amd64.tar.gz && tar -zxvf wal-g-pg-ubuntu-20.04-amd64.tar.gz && sudo mv wal-g-pg-ubuntu-20.04-amd64 /usr/local/bin/wal-g

    sudo ls -l /usr/local/bin/wal-g
    sudo rm -rf /home/backups && sudo mkdir /home/backups && sudo chmod 777 /home/backups

  Создаю файл walg.json в домашней директории postgres. Заношу в него данные. 

    sudo su postgres
    nano ~/.walg.json

    {
        "WALG_FILE_PREFIX": "/home/backups",
        "WALG_COMPRESSION_METHOD": "brotli",
        "WALG_DELTA_MAX_STEPS": "5",
        "PGDATA": "/var/lib/postgresql/15/main",
        "PGHOST": "/var/run/postgresql/.s.PGSQL.5432"
    }


    mkdir /var/lib/postgresql/15/main/log

  Заношу данные в postgresql.auto.conf
    echo "wal_level=replica" >> /var/lib/postgresql/15/main/postgresql.auto.conf
    echo "archive_mode=on" >> /var/lib/postgresql/15/main/postgresql.auto.conf
    echo "archive_command='wal-g wal-push \"%p\" >> /var/lib/postgresql/15/main/log/archive_command.log 2>&1' " >> /var/lib/postgresql/15/main/postgresql.auto.conf 
    echo "archive_timeout=60" >> /var/lib/postgresql/15/main/postgresql.auto.conf 
    echo "restore_command='wal-g wal-fetch \"%f\" \"%p\" >> /var/lib/postgresql/15/main/log/restore_command.log 2>&1' " >> /var/lib/postgresql/15/main/postgresql.auto.conf

    cat ~/15/main/postgresql.auto.conf

  Перезапускаю кластер PostgreSQL

    sudo pg_ctlcluster 15 main stop
    sudo pg_ctlcluster 15 main start
    sudo pg_ctlcluster 15 main status

    cd /home/backups

  Создаю новую базу данных
    sudo -u postgres psql

    CREATE DATABASE otus;

 Создаю таблицу в этой базе данных и заполняю ее тестовыми данными

    create table test(i int);
    insert into test values (10), (20), (30);
    select * from test;
    \q

  Делаю бэкап

    wal-g backup-push /var/lib/postgresql/15/main 

    cat /var/log/postgresql/postgresql-15-main.log
    cat /var/lib/postgresql/15/main/log/archive_command.log

    wal-g backup-list

    psql otus
    UPDATE test SET i = 3 WHERE i = 30;

  Делаю delta

    wal-g backup-push /var/lib/postgresql/15/main

    wal-g backup-list

  Делаю restore 

  Создаю кластер main2  

    pg_createcluster 15 main2

  Удаляю данные по кластеру 

    rm -rf /var/lib/postgresql/15/main2

  Делаю restore 

    wal-g backup-fetch /var/lib/postgresql/15/main2 LATEST


  Делаю файл для восстановления из архивов wal

    touch "/var/lib/postgresql/15/main2/recovery.signal"

  Стартую кластер main2 

    pg_ctlcluster 15 main2 start

  Смотрю таблицу test в базе otus на кластере main2 

    psql -p 5433 otus -c "select * from test;"

  Смотрю таблицу test в базе otus на кластере main 

    psql -p 5432 otus -c "select * from test;"

 # Данные идентичны

