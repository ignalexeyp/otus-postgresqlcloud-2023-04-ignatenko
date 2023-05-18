# Цель:
  Развернуть инстанс Постгреса в ВМ в GCP
  Оптимизировать настройки



### Развернуть Постгрес на ВМ

  Создал виртуальную машину в ЯО

    yc compute instance create --name postgreshw4 --hostname postgreshw4 --cores 2 --memory 4 --create-boot-disk size=40G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --zone ru-central1-a --metadata-from-file ssh-keys=C:\Users\AlexeyI\alexeyi.txt

  Подключился через MobaXterm
  Поставьте на нее PostgreSQL 15

    sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15 htop iotop atop unzip pgtop lynx iftop

    sudo sh -c 'echo "listen_addresses = '"'*'"'" >> /etc/postgresql/15/main/postgresql.conf'
    sudo sh -c 'echo "host    all             all             0.0.0.0/0              scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'
    sudo sed -i 's|host    all             all             127.0.0.1/32            scram-sha-256|host    all             all             127.0.0.1/32            trust|g' /etc/postgresql/15/main/pg_hba.conf
    sudo systemctl restart postgresql.service
    sudo -u postgres psql
    alter user postgres with password 'postgres';

### Протестировать pgbench

  Для тестированием pgbench создаем базу pgbench_test и заливаем в неё данные
  
    sudo psql -U postgres -h localhost
    create database pgbench_test;

  Посмотрим max_connections для установки в тест pgbench 

    select * from pg_settings where name='max_connections';
    \q

    sudo cat /etc/postgresql/15/main/postgresql.conf

    sudo -iu postgres pgbench -s 10 pgbench_test -i

  Запускаю базовый теста pgbench

    -c: количество одновременных клиентов или сеансов БД, которое нужно симулировать.
    -j: количество рабочих потоков, которые pgbench будет использовать во время теста.
    -P: отображает прогресс и метрики каждые 20 секунд.
    -T: запустит тест на 240 секунд (4 минуты).

    sudo -iu postgres pgbench -c 50 -j 2 -P 20 -T 240 pgbench_test

    scaling factor: 10
    query mode: simple
    number of clients: 50
    number of threads: 2
    maximum number of tries: 1
    duration: 240 s
    number of transactions actually processed: 307547
    number of failed transactions: 0 (0.000%)
    latency average = 39.015 ms
    latency stddev = 52.288 ms
    initial connection time = 76.775 ms
    tps = 1281.095518 (without initial connection time)

### Выставить оптимальные настройки

  Захожу на сайт  https://pgtune.leopard.in.ua/#/. Ввожу данные кластера. Смотрю рекомендуемые параметры.

    # DB Version: 15
    # OS Type: linux
    # DB Type: mixed
    # Total Memory (RAM): 4 GB
    # CPUs num: 2
    # Data Storage: ssd
    max_connections = 100
    shared_buffers = 1GB
    effective_cache_size = 3GB
    maintenance_work_mem = 256MB
    checkpoint_completion_target = 0.9
    wal_buffers = 16MB
    default_statistics_target = 100
    random_page_cost = 1.1
    effective_io_concurrency = 200
    work_mem = 2621kB
    min_wal_size = 1GB
    max_wal_size = 4GB

  Захожу на сайт  http://pgconfigurator.cybertec.at/. Ввожу данные кластера. Сформированный файл postgresql.conf прилагается.

  Меняю параметры на кластере на параметры полученные на сайте https://pgtune.leopard.in.ua/#/.

    sudo nano /etc/postgresql/15/main/postgresql.conf
    sudo systemctl restart postgresql.service

### Проверить насколько выросла производительность

  Запускаю базовый теста pgbench

    sudo -iu postgres pgbench -c 50 -j 2 -P 20 -T 240 pgbench_test

    scaling factor: 10
    query mode: simple
    number of clients: 50
    number of threads: 2
    maximum number of tries: 1
    duration: 240 s
    number of transactions actually processed: 335194
    number of failed transactions: 0 (0.000%)
    latency average = 35.795 ms
    latency stddev = 37.117 ms
    initial connection time = 87.126 ms
    tps = 1396.201933 (without initial connection time)

  Меняю параметры на кластере на параметры полученные на сайте http://pgconfigurator.cybertec.at/.

    sudo nano /etc/postgresql/15/main/postgresql.conf

    sudo systemctl restart postgresql.service

  Запускаю базовый теста pgbench

    sudo -iu postgres pgbench -c 50 -j 2 -P 20 -T 240 pgbench_test

    scaling factor: 10
    query mode: simple
    number of clients: 50
    number of threads: 2
    maximum number of tries: 1
    duration: 240 s
    number of transactions actually processed: 334819
    number of failed transactions: 0 (0.000%)
    latency average = 35.836 ms
    latency stddev = 33.797 ms
    initial connection time = 83.318 ms
    tps = 1394.674856 (without initial connection time)

### Настроить кластер на оптимальную производительность не обращая внимания на стабильность БД

  Отключаю автовакуум

    sudo nano /etc/postgresql/15/main/postgresql.conf
    autovacuum = off
    sudo systemctl restart postgresql.service

  Запускаю базовый теста pgbench

    sudo -iu postgres pgbench -c 50 -j 2 -P 20 -T 240 pgbench_test


    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 10
    query mode: simple
    number of clients: 50
    number of threads: 2
    maximum number of tries: 1
    duration: 240 s
    number of transactions actually processed: 335813
    number of failed transactions: 0 (0.000%)
    latency average = 35.736 ms
    latency stddev = 34.985 ms
    initial connection time = 90.121 ms
    tps = 1397.642609 (without initial connection time)

  Включаю ассинхронный коммит

    sudo -u postgres psql
    ALTER SYSTEM SET synchronous_commit = off;
    sudo systemctl restart postgresql.service
    sudo -iu postgres pgbench -c 50 -j 2 -P 20 -T 240 pgbench_test

    transaction type: <builtin: TPC-B (sort of)>
    scaling factor: 10
    query mode: simple
    number of clients: 50
    number of threads: 2
    maximum number of tries: 1
    duration: 240 s
    number of transactions actually processed: 507094
    number of failed transactions: 0 (0.000%)
    latency average = 23.658 ms
    latency stddev = 7.336 ms
    initial connection time = 92.273 ms
    tps = 2112.715211 (without initial connection time)
