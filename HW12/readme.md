## Развернуть HA кластер

# Цель:
  развернуть высокодоступный кластер PostgeSQL собственными силами
  развернуть высокодоступный сервис на базе PostgeSQL на базе одного из 3-ки ведущих облачных провайдеров - AWS, GCP и Azure

   Кластер разворачивался с использованием clustercontrol

   Для использования clustercontrol зарегистрировался на https://severalnines.com/get-started/#clustercontrol и получил пробную
   пробную версию сроком на 30 дней (Регистрация.jpg). 

   Для созлания кластера развернул шесть виртуальных машин ubuntu на платформе yandex cloud
   PS C:\Users\AlexeyI> yc compute instances list
   +----------------------+-------------+---------------+---------+----------------+-------------+
   |          ID          |    NAME     |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
   +----------------------+-------------+---------------+---------+----------------+-------------+
   | fhmahoj11j2k6frmto9r | vm-hw12-pg3 | ru-central1-a | RUNNING | 84.201.133.63  | 10.128.0.32 |
   | fhmei211dakde38muu5b | vm-hw12     | ru-central1-a | RUNNING | 84.201.132.30  | 10.128.0.25 |
   | fhmi4fokdjnai1i70tfv | vm-hw12-pg2 | ru-central1-a | RUNNING | 158.160.48.130 | 10.128.0.15 |
   | fhmql4vb4036eia9acer | vm-hw12-hp  | ru-central1-a | RUNNING | 84.252.130.115 | 10.128.0.34 |
   | fhmsvcnkb3mvacqv1191 | vm-hw12-hp2 | ru-central1-a | RUNNING | 51.250.90.191  | 10.128.0.7  |
   | fhmtl4ahpb7atof9v3sj | vm-hw12-pg1 | ru-central1-a | RUNNING | 158.160.98.226 | 10.128.0.30 |
   +----------------------+-------------+---------------+---------+----------------+-------------+
   vm-hw12 - для кластера,
   vm-hw12-pg1, vm-hw12-pg2, vm-hw12-pg3 - postgresql, pgbouncer
   vm-hw12-hp, vm-hw12-hp2 - HAProxy, keepalived 
   
   На vm-hw12 выполнил
   wget -O install-cc https://severalnines.com/scripts/install-cc?mkPYvsa5guz5TSK%2BPvb63FB0phwaNA%3D%3D,
   chmod +x install-cc
   sudo su root
   S9S_CMON_PASSWORD=CMON321 S9S_ROOT_PASSWORD=ROOT321 ./install-cc
   exit 
   ssh-keygen -t rsa 

   Записал публичный ключ виртуальной машины vm-hw12 в файл /home/alexeyi/.ssh/authorized_keys на всех
   виртуальных машинах входящих в кластел

   В браузере подключился к http://84.201.132.30/clustercontrol и создал администратора, введя действительный адрес электронной почты и пароль.

   В режиме Deploy Database Cluster выбрал PostgreSql и последовательно настроил ноды PostgeSql, HAProxy, keepalived, pgbouncer
   согласно инстукции https://severalnines.com/blog/how-deploy-postgresql-high-availability/. 
   Топология развернутого кластера в Топология кластера.jpg.  

  