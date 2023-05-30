# Кластер Patroni

# Цель:
  Развернуть HA кластер

   Имеем 8 виртуальных машин (инстансов) ubuntu 22.04.5 LTS server с SSH , но без обновлений 
   vm-postgresql-dev-5			ip 10.128.3.195
   vm-postgresql-dev-6			ip 10.128.3.196
   vm-postgresql-dev-7			ip 10.128.3.197
   vm-postgresql-dev-8			ip 10.128.3.198
   vm-postgresql-dev-9			ip 10.128.3.199
   vm-postgresql-dev-10			ip 10.128.3.200
   vm-postgresql-dev-11.prod.ru	        ip 10.128.3.169
   vm-postgresql-dev-12.prod.ru	        ip 10.128.3.170
   Количество процессоров: 2
   Объем дискового пространства (GB): 80
   Объем оперативной памяти (GB): 2

   На машинах vm-postgresql-dev-5 vm-postgresql-dev-6 vm-postgresql-dev-7 устанавливаю etcd
   На машинах vm-postgresql-dev-8 vm-postgresql-dev-9 vm-postgresql-dev-10 устанавливаю PostgreSql, здесь же будут размещаться базы данных.
   Кроме этого на этих машинах устанавливается patroni и pgbouncer.
   На машинах vm-postgresql-dev-11.prod.ru vm-postgresql-dev-12.prod.ru устанавливаю HAProxy и keepalived.
   Сейчас все машины одинаковые по характеристикам. В реальном кластере машины с etcd не требуют таких же ресурсов как машины с БД PostgreSql.
   Машины с HAProxy и keepalived также могут иметь характеристики, отличные от характеристик машин с Postgresql, особенно в части дисковых
   массивов. 

### УСТАНОВКА ETCD


  Обновиляю локальный индекс пакетов сервера. На всех нодах выполняю: 

   sudo apt-get update; apt upgrade -y 
   sudo apt install -y etcd  

  Устанавливаю etcd

   for i in {5,6,7}; do  ssh vm-postgresql-dev-$i --command='sudo apt update && sudo apt upgrade -y && sudo apt install -y etcd' & done;

  Проверяю, что c etcd.

   for i in vm-postgresql-dev-{5,6,7}; do ssh ${i} 'hostname; ps -aef | grep etcd | grep -v grep'; done 


  Останавливаю сервисы etcd

   for i in vm-postgresql-dev-{5,6,7}; do ssh ${i} 'sudo systemctl stop etcd'; done 

  Добавляю в файлы с конфигами /etc/default/etcd. При работающем DNS можно прописывать имена инстасов, иначе IP адреса.

   (ETCD_INITIAL_CLUSTER="vm-postgresql-dev-5=http://vm-postgresql-dev-5:2380,vm-postgresql-dev-6=http://vm-postgresql-dev-6:2380,vm-postgresql-dev-7=http://vm-postgresql-dev-7:2380")
  
  Z cделал 

   (ETCD_INITIAL_CLUSTER="vm-postgresql-dev-5=http://10.128.3.195:2380,vm-postgresql-dev-6=http://10.128.3.196:2380,vm-postgresql-dev-7=http://10.128.3.197:2380")

  Я прописывал IP адреса, хотя DNS работает. Посмотреть DNS сервер cat /etc/resolv.conf.

  Инстанс vm-postgresql-dev-5

   sudo  nano  /etc/default/etcd

  Добавляю

   ETCD_NAME="vm-postgresql-dev-5"
   ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
   ETCD_ADVERTISE_CLIENT_URLS="http://10.128.3.195:2379"
   ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
   ETCD_INITIAL_ADVERTISE_PEER_URLS="10.128.3.195:2380"
   ETCD_INITIAL_CLUSTER_TOKEN="STPatroniCluster"
   ETCD_INITIAL_CLUSTER="vm-postgresql-dev-5=http://10.128.3.195:2380,vm-postgresql-dev-6=http://10.128.3.196:2380,vm-postgresql-dev-7=http://10.128.3.197:2380"
   ETCD_INITIAL_CLUSTER_STATE="new"
   ETCD_DATA_DIR="/var/lib/etcd"

  Инстанс vm-postgresql-dev-6

   sudo  nano  /etc/default/etcd

   ETCD_NAME="vm-postgresql-dev-6"
   ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
   ETCD_ADVERTISE_CLIENT_URLS="http://10.128.3.196:2379"
   ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
   ETCD_INITIAL_ADVERTISE_PEER_URLS="http://10.128.3.196:2380"
   ETCD_INITIAL_CLUSTER_TOKEN="STPatroniCluster"
   ETCD_INITIAL_CLUSTER="vm-postgresql-dev-5=http://10.128.3.195:2380,vm-postgresql-dev-6=http://10.128.3.196:2380,vm-postgresql-dev-7=http://10.128.3.197:2380"
   ETCD_INITIAL_CLUSTER_STATE="new"
   ETCD_DATA_DIR="/var/lib/etcd"

  Инстанс vm-postgresql-dev-6

   sudo  nano  /etc/default/etcd

   ETCD_NAME="vm-postgresql-dev-7"
   ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"
   ETCD_ADVERTISE_CLIENT_URLS="http://10.128.3.197:2379"
   ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
   ETCD_INITIAL_ADVERTISE_PEER_URLS="10.128.3.197:2380"
   ETCD_INITIAL_CLUSTER_TOKEN="STPatroniCluster"
   ETCD_INITIAL_CLUSTER="vm-postgresql-dev-5=http://10.128.3.195:2380,vm-postgresql-dev-6=http://10.128.3.196:2380,vm-postgresql-dev-7=http://10.128.3.197:2380"
   ETCD_INITIAL_CLUSTER_STATE="new"
   ETCD_DATA_DIR="/var/lib/etcd"

  Старт на всех трех инстансах (vm-postgresql-dev-5 vm-postgresql-dev-6 vm-postgresql-dev-7)

   for i in vm-postgresql-dev-{5,6,7}; do ssh ${i} 'sudo systemctl start etcd'; done

  Проверка автозагрузки на каждом инстансе

   systemctl is-enabled etcd

  Проверка etcd-кластера. Запускаем на одном инстансе etcd-кластера. 

   etcdctl cluster-health

### УСТАНОВКА POSTGRESQL

  Устанавливаю PostgreSql на инстансы vm-postgresql-dev-8 vm-postgresql-dev-9 vm-postgresql-dev-10

for i in vm-postgresql-dev-{8,9,10}; do ssh ${i} 'sudo apt update && sudo apt upgrade -y -q && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdg.list && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14'; done


  Убеждаюсь, что кластера Postgresql стартовали

   for i in vm-postgresql-dev-{8,9,10}; do ssh ${i} 'hostname; pg_lsclusters'; done

### УСТАНОВКА PATRONI

  Устанавливаю python на все инстансы с Postgresql 

   sudo apt-get install -y python3 python3-pip git mc
   sudo pip3 install psycopg2-binary 

  После установки ПО останавливаем и удаляем экземлпяр постгреса который запускается по-умолчанию

   sudo -u postgres pg_ctlcluster 14 main stop
   --sudo systemctl stop postgresql@14-main
   sudo -u postgres pg_dropcluster 14 main 

  убеждемся что их нет

   sudo pg_lsclusters

  устанавливаем патрони 

   sudo pip3 install patroni[etcd]

  делаем симлинк

   sudo ln -s /usr/local/bin/patroni /bin/patroni

  включаем старт сервиса
  для каждого инстанса с patroni вносим информацию в patroni.service (пример в файле patroni.service)

   sudo nano /etc/systemd/system/patroni.service

   [Unit]
   Description=High availability PostgreSQL Cluster
   After=syslog.target network.target

   [Service]
   Type=simple
   User=postgres
   Group=postgres
   ExecStart=/usr/local/bin/patroni /etc/patroni.yml
   KillMode=process
   TimeoutSec=30
   Restart=no

   [Install]
   WantedBy=multi-user.target


  для каждого инстанса с patroni вносим информацию в /etc/patroni.yml шаблон один но надо проставить имена и хосты для каждой ноды свои 
  пример для 10.128.3.198

   sudo nano /etc/patroni.yml


   scope: patroni
   name: vm-postgresql-dev-8

   restapi:
     listen: 10.128.3.198:8008
     connect_address: 10.128.3.198:8008
   etcd:
    hosts: vm-postgresql-dev-5:2379,vm-postgresql-dev-6:2379,vm-postgresql-dev-7:2379
   bootstrap:
     dcs:
       ttl: 30
       loop_wait: 10
       retry_timeout: 10
       maximum_lag_on_failover: 1048576
       postgresql:
         use_pg_rewind: true
         parameters:
     initdb:
     - encoding: UTF8
     - data-checksums
     pg_hba:
     - host replication replicator 10.128.0.0/8 md5
     - host all all 10.128.0.0/8 md5
     users:
       admin:
         password: admin321
         options:
           - createrole
           - createdb
   postgresql:
     listen: 127.0.0.1, 10.128.3.198:5432
     connect_address: 10.128.3.198:5432
     data_dir: /var/lib/postgresql/14/main
     bin_dir: /usr/lib/postgresql/14/bin
     pgpass: /tmp/pgpass0
     authentication:
       replication:
         username: replicator
         password: reppass321
       superuser:
         username: postgres
         password: zalando321
       rewind:  # Has no effect on postgres 10 and lower
         username: rewinduser
         password: rewindpassword321
     parameters:
       unix_socket_directories: '.'
   tags:
       nofailover: false
       noloadbalance: false
       clonefrom: false
       nosync: false

  запускаем patroni

   sudo -u postgres patroni /etc/patroni.yml

   sudo systemctl is-enabled patroni 
   sudo systemctl enable patroni 
   sudo systemctl start patroni 
   sudo systemctl stop patroni 
   sudo patronictl -c /etc/patroni.yml list 
   sudo systemctl status patroni 

 
  В зависимости от нод меняется:

   listen: 127.0.0.1, 10.128.3.198:5432
   connect_address: 10.128.3.198:5432

  посмотреть состояние patrony

   sudo patronictl -c /etc/patroni.yml list 


### pgbouncer

   for i in vm-postgresql-dev-{8,9,10}; do ssh ${i} 'sudo apt install -y pgbouncer'; done

  Создал базу chicago  

   create database chicago;

   sudo nano /etc/pgbouncer/pgbouncer.ini

  Вставляем в /etc/pgbouncer/pgbouncer.ini


[databases]
chicago = host=127.0.0.1 port=5432 dbname=chicago 
[pgbouncer]
logfile = /var/log/postgresql/pgbouncer.log
pidfile = /var/run/postgresql/pgbouncer.pid
listen_addr = *
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
admin_users = postgres

  Если необходим доступ к нескольким базам данным, добавляем например

   testuser = host=127.0.0.1 port=5432 dbname=testuser  



   !!! Имелась проблема с подключением к БД со стороны клиента (pgAdmin4, DataGrip). 
   !!! Необходимо раскомментарить параметр ;;ignore_startup_parameters = extra_float_digits в /etc/pgbouncer/pgbouncer.ini

  Установил  net-tools посмотрим процессы

   sudo apt install net-tools
   netstat -pltn

   sudo systemctl status pgbouncer 
   sudo systemctl stop pgbouncer 
   sudo systemctl start pgbouncer
 

   sudo -u postgres psql -h localhost
   create user admindb with password 'root123';
   select * from users;

  \du
 - list role

  Необходимо внести информацию в /etc/pgbouncer/userlist.txt  о пользователях, подключающихся через pgbouncer

   sudo -u postgres psql -h localhost
   postgres=# select usename,passwd from pg_shadow;

     usename   |                                                                passwd
   ------------+---------------------------------------------------------------------------------------------------------------------------------------
    postgres   | SCRAM-SHA-256$4096:Z7I9sYPjjLJiDGlEa2NGjg==$Xz1MZAcKJCF+dxJhRN9WcHaBt2WnsrLUa1PbwxVpiCU=:YmNHdjAARNXVYzeuEkRlHMPlc8LJsNTUXmcERVHz9y8=
    replicator | SCRAM-SHA-256$4096:Cky8wsNlEDSjU+qAq3jlpg==$RKaEDaCCkyrGehhf48U98SAM6y607LrtueJPSI05hdM=:IYLeoy1Y7SLIME5eQCXltBNefv8dk15gyoz0pO/i1VQ=
    rewinduser | SCRAM-SHA-256$4096:ulschQClUbXOT8rvWxY85A==$bAfAcS+QPH0IPY47AuWzbk6O6C2u/963l4RZVCBZYE4=:96nxtnoFTPCokdJ9H/eT8gjyD1q2NZpQW2ojGCw05GA=
    admin      | SCRAM-SHA-256$4096:x02YbYPWCcyTnaXVQOCOSA==$3gQyFZ2ox6DKrWNS7pCDn/nzrEdaPPQ0BKVCoMcTq9g=:pRt249q2M/L2sqQYVDS+rgY8YMeTnF0KZCkaVReHoHo=
    admindb    | SCRAM-SHA-256$4096:fJOMTtmAfIRaG9PPFkaLkQ==$1tlGA6bXc+At8+1bC7JPxjWcKkjV4R1ScUg6/DjC3PM=:d3suEa2k+K4n8qLMEtH8toQLXy47RwdZ1LgW9/norZg=
    testuser   | SCRAM-SHA-256$4096:g0UGgROg54Ifbtv9eaOWpQ==$Fh6t0lwQJiDGd66EPDKmm7korJlUlv5c0zoIXuYaT6k=:sj4aLUYazRLJRP1dDltc36o6YQRISzI3r6GBQlDxZ74=

   sudo nano /etc/pgbouncer/userlist.txt

   "postgres"  "SCRAM-SHA-256$4096:Z7I9sYPjjLJiDGlEa2NGjg==$Xz1MZAcKJCF+dxJhRN9WcHaBt2WnsrLUa1PbwxVpiCU=:YmNHdjAARNXVYzeuEkRlHMPlc8LJsNTUXmcERVHz9y8="
   "testuser"  "SCRAM-SHA-256$4096:g0UGgROg54Ifbtv9eaOWpQ==$Fh6t0lwQJiDGd66EPDKmm7korJlUlv5c0zoIXuYaT6k=:sj4aLUYazRLJRP1dDltc36o6YQRISzI3r6GBQlDxZ74="

  рестарт pg_bouncer

   sudo systemctl restart pgbouncer 

  При падении сам стартует

   sudo nano /lib/systemd/system/pgbouncer.service
   Restart=always


### Установка HAPROXY


  Выполнил на нодах vm-postgresql-dev-11.prod.ru vm-postgresql-dev-12.prod.ru

   sudo apt install -y --no-install-recommends software-properties-common && sudo add-apt-repository -y ppa:vbernat/haproxy-2.5 && sudo apt install -y haproxy=2.5.\*

  Проверил состояния на нодах haproxy

   curl -v 10.128.3.200:8008/master

  Настроим /etc/haproxy/haproxy.cfg.

   sudo nano /etc/haproxy/haproxy.cfg


   listen postgres_write
       bind *:5432
       mode            tcp
       option httpchk
       http-check connect
       http-check send meth GET uri /master
       http-check expect status 200
       default-server inter 10s fall 3 rise 3 on-marked-down shutdown-sessions
       server vm-postgresql-dev-8 10.128.3.198:6432 check port 8008
       server vm-postgresql-dev-9 10.128.3.199:6432 check port 8008
       server vm-postgresql-dev-10 10.128.3.200:6432 check port 8008

   listen postgres_read
       bind *:5433
       mode            tcp
       http-check connect
       http-check send meth GET uri /replica
       http-check expect status 200
       default-server inter 10s fall 3 rise 3 on-marked-down shutdown-sessions
       server vm-postgresql-dev-8 10.128.3.198:6432 check port 8008
       server vm-postgresql-dev-9 10.128.3.199:6432 check port 8008
       server vm-postgresql-dev-10 10.128.3.200:6432 check port 8008

  Выполняем рестарт haproxy.service и смотрим статус

   sudo systemctl restart haproxy.service
   sudo systemctl status haproxy.service

  Смотрим лог

   sudo cat /var/log/haproxy.log


### Настройка keepalived на хостах с HAproxy


  HAproxy устанавливается на нодах vm-postgresql-dev-11.prod.ru vm-postgresql-dev-12.prod.ru

   sudo apt install -y keepalived

  Включаем виртуальный сетевой коммутатор

   sudo nano /etc/sysctl.conf

  дописываем

   net.ipv4.ip_nonlocal_bind=1

   sudo sysctl -p

  посмотрим на какой интерфейс нужно добавить виртуальный ip

   ip a

   sudo nano /etc/keepalived/keepalived.conf

   global_defs {
   # Keepalived process identifier
   lvs_id haproxy_DH
   }
   # Script used to check if HAProxy is running
   vrrp_script check_haproxy {
   script "killall -0 haproxy"
   interval 2
   weight 2
   }
   # Virtual interface
   # The priority specifies the order in which the assigned interface to take over in a failover
   vrrp_instance VI_01 {
   state MASTER
   interface eth0
   virtual_router_id 51
   priority 101
   # The virtual ip address shared between the two loadbalancers
   virtual_ipaddress {
   10.128.3.230
   }
   track_script {
   check_haproxy
   }
   }

sudo service keepalived start

  посмотрим успешность добавления IP

   ip a






























