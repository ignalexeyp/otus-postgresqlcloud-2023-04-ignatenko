# Цель:
  создавать дополнительный диск для уже существующей виртуальной машины, размечать его и делать на нем файловую систему
  переносить содержимое базы данных PostgreSQL на дополнительный диск
  переносить содержимое БД PostgreSQL между виртуальными машинами



### Cоздайте виртуальную машину c Ubuntu 20.04 LTS (bionic) в GCE типа e2-medium в default VPC в любом регионе и зоне, например us-central1-a или ЯО/VirtualBox

  Создал виртуальную машину в ЯО

    yc compute instance create --name postgreshw3 --hostname postgreshw3 --cores 2 --memory 4 --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --zone ru-central1-a --metadata-from-file ssh-keys=C:\Users\AlexeyI\alexeyi.txt

    yc compute instance get postgreshw3

  Подключился через MobaXterm

    sudo apt -y install mc

### Поставьте на нее PostgreSQL 15 через sudo apt

    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-15

    sudo sh -c 'echo "listen_addresses = '"'*'"'" >> /etc/postgresql/15/main/postgresql.conf'
    sudo sh -c 'echo "host    all             all             0.0.0.0/0              scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'
    sudo sed -i 's|host    all             all             127.0.0.1/32            scram-sha-256|host    all             all             127.0.0.1/32            trust|g' /etc/postgresql/15/main/pg_hba.conf
    sudo systemctl restart postgresql.service
    sudo -u postgres psql
    alter user postgres with password 'postgres';

### Проверьте что кластер запущен через sudo -u postgres pg_lsclusters

    sudo -u postgres pg_lsclusters

### Зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым

    sudo psql -U postgres -h localhost
    create table test(i1 int, c1 varchar(100));
    insert into test values(1, 'First');
    insert into test values(2, 'Second');
    /q

### Остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop

    sudo -u postgres pg_ctlcluster 15 main stop   

### Cоздайте новый standard persistent диск GKE через Compute Engine -> Disks в том же регионе и зоне что GCE инстанс размером например 10GB - или аналог в другом облаке/виртуализации

    sudo lsblk
    Мой диск vdb

### Добавьте свеже-созданный диск к виртуальной машине - надо зайти в режим ее редактирования и дальше выбрать пункт attach existing disk

    ls -la /dev/disk/by-id

### Проинициализируйте диск согласно инструкции и подмонтировать файловую систему, только не забывайте менять имя диска на актуальное, в вашем случае это скорее всего будет /dev/sdb - https://www.digitalocean.com/community/tutorials/how-to-partition-and-format-storage-devices-in-linux

    sudo apt update
    sudo apt install parted
    sudo parted -l | grep Error
    sudo parted /dev/vdb mklabel gpt
    sudo lsblk
    sudo parted -a opt /dev/vdb mkpart primary ext4 0% 100%
    sudo lsblk
    sudo mkfs.ext4 -L dataparthw3 /dev/vdb1  
    sudo lsblk --fs
    sudo lsblk -o NAME,FSTYPE,LABEL,UUID,MOUNTPOINT

    sudo mkdir -p /mnt/data
    sudo mount -o defaults /dev/vdb1 /mnt/data

    sudo nano /etc/fstab
    Добавляю строку:
    LABEL=dataparthw3 /mnt/data ext4 defaults 0 2

    sudo mount -a


### Перезагрузите инстанс и убедитесь, что диск остается примонтированным (если не так смотрим в сторону fstab)

    sudo lsblk
    Диск остается примонтированным.

### Сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/

    sudo chown -R postgres:postgres /mnt/data/

### Перенесите содержимое /var/lib/postgresql/15 в /mnt/data - mv /var/lib/postgresql/15 /mnt/data

    sudo mv /var/lib/postgresql/15 /mnt/data

### Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start

    sudo -u postgres pg_ctlcluster 15 main start

### Напишите получилось или нет и почему

    Сообщение:  
    "Error: /var/lib/postgresql/15/main is not accessible or does not exist"
    Папка  /var/lib/postgresql/15/main  отсутствует,  перенесена /mnt/data.

### Задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/14/main который надо поменять и поменяйте его

 Напишите что и почему поменяли

    sudo nano /etc/postgresql/15/main/postgresql.conf
    data_directory = '/var/lib/postgresql/15/main'
    меняю на '/mnt/data/15/main' т.к. она перенесена.

### Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start

    sudo -u postgres pg_ctlcluster 15 main start

### Yапишите получилось или нет и почему

    Сообщение:
    "Warning: the cluster will not be running as a systemd service. Consider using systemctl:
    sudo systemctl start postgresql@15-main
    Removed stale pid file."
   
### Зайдите через через psql и проверьте содержимое ранее созданной таблицы

    sudo psql -U postgres -h localhost
    select * from test;

    sudo psql -U postgres -h localhost
    Password for user postgres:
    psql (15.3 (Ubuntu 15.3-1.pgdg22.04+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
    Type "help" for help.
    postgres=# select * from test;
    i1 |   c1
    ----+--------
    1 | First
    2 | Second
    (2 rows)

### Содержимое ранее созданной таблицы не изменилось.

задание со звездочкой *: не удаляя существующий GCE инстанс/ЯО сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgresql, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось.


    yc compute instance create --name postgreshw3hi --hostname postgreshw3hi --cores 2 --memory 4 --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --zone ru-central1-a --metadata-from-file ssh-keys=C:\Users\AlexeyI\alexeyi.txt

    sudo apt -y install mc

    sudo apt update && sudo apt upgrade -y && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql-15 postgresql-client15
    sudo sh -c 'echo "listen_addresses = '"'*'"'" >> /etc/postgresql/15/main/postgresql.conf'
    sudo sh -c 'echo "host    all             all             0.0.0.0/0              scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf'
    sudo sed -i 's|host    all             all             127.0.0.1/32            scram-sha-256|host    all             all             127.0.0.1/32            trust|g' /etc/postgresql/15/main/pg_hba.conf
    sudo systemctl restart postgresql.service
    sudo psql -U postgres -h 127.0.0.1 -c "alter user postgres with password 'postgres';"

    sudo -u postgres pg_ctlcluster 15 main stop   

    sudo rm -fr /var/lib/postgresql

