# Цель:
  развернуть ВМ в GCP/ЯО/Аналоги
  установить туда докер
  установить PostgreSQL в Docker контейнере
  настроить контейнер для внешнего подключения


### сделать в GCE/ЯО/Аналоги инстанс с Ubuntu 20.04

  внутренний ip 10.128.0.12
  публичный ip 84.201.174.243
  идентификатор fhm47r7asu94oapj1gtv

  Обновляю существующий список пакетов.
  Затем устанавливаю несколько необходимых пакетов, которые позволяют apt использовать пакеты через HTTPS.

    sudo apt update
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker

  Использу docker network create команду для создания определяемой пользователем мостовой сети.

    sudo docker network create pgserv_docker_net
    cd89be346cbedd5081f9ebb3c0f3a9cd3cd44c19470c11095a86adebe9e6bd71

  Смотрю данные по сети

    sudo docker network inspect pgserv_docker_net

  Устанавливаем docker  Postgresql.

    sudo mkdir -p /var/lib/postgresql
    sudo docker run --name pgserv_docker -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=passpostgres -e POSTGRES_DB=testdb -d postgres:14 postgres
    4aca1d3207ce2e42cce3800591d2b547e08504f55ee8576457cccfd99c00f5ba

    sudo docker ps
    4aca1d3207ce

Подключаю докера к действующей сети.

    sudo docker network connect pgserv_docker_net pgserv_docker
    sudo docker inspect 4aca1d3207ce

### развернуть контейнер с клиентом postgres

  Фактически я устанавливаю PosgreSQl на порт 5431 для возможности использования psql. Не понял, есть ли возможность загрузить докер только с postgresql-client-common postgresql-client. Считаю, моя установка подходит для проверки подключения с одного докера к другому.

    sudo docker run --name psql-client -p 5431:5431 -e POSTGRES_PASSWORD=passpostgres -d postgres
    f7c57a1a65dca44ee90def0ff98844185f8339f6716861ff7b0e8c6e2624ee6c
    sudo docker ps
    f7c57a1a65dc

Подключение докера к действующей сети.

    sudo docker network connect pgserv_docker_net psql-client

### подключиться из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк

    sudo docker exec -it psql-client bash
    psql -h 172.18.0.2 -U postgres -d testdb

    create table towns(id int, name varchar(100));
    insert into towns(id, name) values(1, 'Moscow');
    insert into towns(id, name) values(2, 'Penza');

### подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/Аналоги

    Подключился pgAdmin4 Скриншот прилагаю.

### удалить контейнер с сервером

    sudo docker network disconnect pgserv_docker_net pgserv_docker
    sudo docker stop pgserv_docker
    sudo docker rm pgserv_docker
    sudo docker ps

### создать его заново

    sudo docker run --name pgserv_docker -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=passpostgres -e POSTGRES_DB=testdb -d postgres:14 postgres
    750ada7bdf0d51e2bbbb7690bf0c824ce28ae959c4fef54826c36af9da99da14
    sudo docker ps
    750ada7bdf0d
    sudo docker network connect pgserv_docker_net pgserv_docker

### подключиться снова из контейнера с клиентом к контейнеру с сервером

    sudo docker exec -it psql-client bash
    sudo -u postgres psql -h 172.18.0.2
    sudo docker exec -it psql-client bash
    psql -h 172.18.0.2 -U postgres -d testdb

### проверить, что данные остались на месте

  select * from towns;

  id |  name
  ----+--------
    1 | Moscow
    2 | Penza
    (2 rows)

### Данные остались на месте
