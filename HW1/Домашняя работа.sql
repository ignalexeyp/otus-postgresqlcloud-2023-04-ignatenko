# Домашнее задание по курсу PostgreSQL Cloud Solutions Урок 1 SQL и реляционные СУБД. PostgreSQL в облаках
Cоздать новый проект в Google Cloud Platform, Яндекс облако или на любых ВМ, например postgres2023-, где yyyymmdd год, месяц и день вашего рождения (имя проекта должно быть уникально на уровне GCP)
далее создать инстанс виртуальной машины Compute Engine с дефолтными параметрами - 1-2 ядра, 2-4Гб памяти, любой линукс, на курсе Ubuntu 100%
***создал в https://console.cloud.yandex.ru/***
добавить свой ssh ключ в GCE metadata
зайти удаленным ssh (первая сессия), не забывайте про ssh-add
поставить PostgreSQL из пакетов apt install
зайти вторым ssh (вторая сессия)
запустить везде psql из под пользователя postgres
выключить auto commit
сделать в первой сессии новую таблицу и наполнить ее данными
create table persons(id serial, first_name text, second_name text);
insert into persons(first_name, second_name) values('ivan', 'ivanov');
insert into persons(first_name, second_name) values('petr', 'petrov');
commit;
посмотреть текущий уровень изоляции: show transaction isolation level
начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
в первой сессии добавить новую запись
insert into persons(first_name, second_name) values('sergey', 'sergeev');
сделать select * from persons во второй сессии
видите ли вы новую запись и если да то почему? 
***записи во второй сессии нет, т.к. дефолтный уровень изоляции Read committed не позволяет "грязное чтение"***
завершить первую транзакцию - commit;
сделать select * from persons во второй сессии
видите ли вы новую запись и если да то почему?
***запись видим, т.к. транзакция зафиксирована***
завершите транзакцию во второй сессии
начать новые но уже repeatable read транзакции - set transaction isolation level repeatable read;
в первой сессии добавить новую запись
insert into persons(first_name, second_name) values('sveta', 'svetova');
сделать select * from persons во второй сессии
видите ли вы новую запись и если да то почему?
***запись не видим  "грязное чтение" не допускается***
завершить первую транзакцию - commit;
сделать select * from persons во второй сессии
видите ли вы новую запись и если да то почему?
***запись не видим  "фантомное чтение" в postgres при уровне изоляции Repeatable Read не допускается***
завершить вторую транзакцию
сделать select * from persons во второй сессии
видите ли вы новую запись и если да то почему?
***запись видим, т.к. транзакции в обеих сессиях закоммичены***

