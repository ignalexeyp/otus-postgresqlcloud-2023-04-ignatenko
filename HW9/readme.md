# Постгрес в minikube

# Цель:
  Развернуть Постгрес в миникубе
  Устанавливаем minikube
  Разворачиваем PostgreSQL 14 через манифест

### Развернуть Постгрес на ВМ

  Создал виртуальную машину в ЯО
    yc compute instance create --name postgreshw3 --hostname postgreshw9 --cores 2 --memory 4 --create-boot-disk size=15G,type=network-ssd,image-folder-id=standard-images,image-family=ubuntu-2204-lts --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 --zone ru-central1-a --metadata-from-file ssh-keys=C:\Users\AlexeyI\alexeyi.txt

  Подключился через MobaXterm

  установка minikube

    sudo apt update && apt upgrade
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    minikube version
      minikube version: v1.30.1
      commit: 08896fd1dc362c097c925146c4a0d0dac715ace0

  установка докера

    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

  настройка репозитория

    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  проверяем

    sudo docker run hello-world
      Unable to find image 'hello-world:latest' locally
      latest: Pulling from library/hello-world
      719385e32844: Pull complete
      Digest: sha256:fc6cf906cbfa013e80938cdf0bb199fbdbb86d6e3e013783e5a766f50f5dbce0
      Status: Downloaded newer image for hello-world:latest
      Hello from Docker!
      This message shows that your installation appears to be working correctly.
      To generate this message, Docker took the following steps:
       1. The Docker client contacted the Docker daemon.
       2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
          (amd64)
       3. The Docker daemon created a new container from that image which runs the
          executable that produces the output you are currently reading.
       4. The Docker daemon streamed that output to the Docker client, which sent it
          to your terminal.
      To try something more ambitious, you can run an Ubuntu container with:
       $ docker run -it ubuntu bash
      Share images, automate workflows, and more with a free Docker ID:
       https://hub.docker.com/
      For more examples and ideas, visit:
       https://docs.docker.com/get-started/

    sudo groupadd docker
      groupadd: group 'docker' already exists

    sudo usermod -aG docker $USER

  Для того чтобы активировать изменения в группах выполняю команду:

    newgrp docker

  Убеждаюсь, что можно запускать dockerкоманды без sudo.

    docker run hello-world
      Hello from Docker!
      This message shows that your installation appears to be working correctly.

  Устанавливаю kubectl

    curl -LO https://dl.k8s.io/release/`curl -LS https://dl.k8s.io/release/stable.txt`/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl
    kubectl version --client
    kubectl version --output=yaml|json




  Стартую minikube

    minikube start
      * minikube v1.30.1 on Ubuntu 22.04 (amd64)
      * Automatically selected the docker driver. Other choices: none, ssh
      * Using Docker driver with root privileges
      * Starting control plane node minikube in cluster minikube
      * Pulling base image ...
      * Downloading Kubernetes v1.26.3 preload ...
          > preloaded-images-k8s-v18-v1...:  397.02 MiB / 397.02 MiB  100.00% 26.27 M
          > gcr.io/k8s-minikube/kicbase...:  373.53 MiB / 373.53 MiB  100.00% 9.51 Mi
      * Creating docker container (CPUs=2, Memory=2200MB) ...
      * Preparing Kubernetes v1.26.3 on Docker 23.0.2 ...
        - Generating certificates and keys ...
        - Booting up control plane ...
        - Configuring RBAC rules ...
      * Configuring bridge CNI (Container Networking Interface) ...
        - Using image gcr.io/k8s-minikube/storage-provisioner:v5
      * Verifying Kubernetes components...
      * Enabled addons: storage-provisioner, default-storageclass
      * Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

    minikube profile list
      |----------|-----------|---------|--------------|------|---------|---------|-------|--------|
      | Profile  | VM Driver | Runtime |      IP      | Port | Version | Status  | Nodes | Active |
      |----------|-----------|---------|--------------|------|---------|---------|-------|--------|
      | minikube | docker    | docker  | 192.168.49.2 | 8443 | v1.26.3 | Running |     1 | *      |
      |----------|-----------|---------|--------------|------|---------|---------|-------|--------|

  Выполняю на другом ssh подключении

    kubectl proxy --address='0.0.0.0' --disable-filter=true
      W0611 19:58:16.193426   61783 proxy.go:175] Request filter disabled, your proxy is vulnerable to XSRF attacks, please be cautious
      Starting to serve on [::]:8001

  Развертывание postgres. Файлы из урока с измененной версией postgres 

    mkdir app
    cd app
    nano Dockerfile
    nano app.py
    nano requirements.txt
    cd ..
    nano postgres.yaml
    nano service.yaml
    nano secrets.yaml
    nano deployment.yaml
    nano app-config.yaml
    kubectl apply -f postgres.yaml
      service/postgres created
      statefulset.apps/postgres-statefulset created
    minikube service postgres --url
      http://192.168.49.2:31392

    minikube service list
      |----------------------|---------------------------|--------------|---------------------------|
      |      NAMESPACE       |           NAME            | TARGET PORT  |            URL            |
      |----------------------|---------------------------|--------------|---------------------------|
      | default              | kubernetes                | No node port |                           |
      | default              | postgres                  |         5432 | http://192.168.49.2:31392 |
      | kube-system          | kube-dns                  | No node port |                           |
      | kubernetes-dashboard | dashboard-metrics-scraper | No node port |                           |
      | kubernetes-dashboard | kubernetes-dashboard      | No node port |                           |
      |----------------------|---------------------------|--------------|---------------------------|

    psql -h 192.168.49.2 -p 31392 -d myapp -U myuser
      Password for user myuser:
      psql (14.8 (Ubuntu 14.8-0ubuntu0.22.04.1))
      Type "help" for help.
    myapp=# CREATE TABLE client(id serial, name text);
    INSERT INTO client(name) values('Ivan');
      CREATE TABLE
      INSERT 0 1
    myapp=# select * from client;
      id | name
     ----+------
       1 | Ivan
     (1 row)

    myapp=# SELECT version();
                                                                 version
      -----------------------------------------------------------------------------------------------------------------------------
       PostgreSQL 14.8 (Debian 14.8-1.pgdg110+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 10.2.1-6) 10.2.1 20210110, 64-bit
      (1 row)





























/***********************************************/

id: fhmmj1p3ikk4vff58sgl
folder_id: b1gc7b69ba8qndsj4tc2
created_at: "2023-06-11T07:24:55Z"
name: postgreshw3
zone_id: ru-central1-a
platform_id: standard-v2
resources:
  memory: "4294967296"
  cores: "2"
  core_fraction: "100"
status: RUNNING
metadata_options:
  gce_http_endpoint: ENABLED
  aws_v1_http_endpoint: ENABLED
  gce_http_token: ENABLED
  aws_v1_http_token: DISABLED
boot_disk:
  mode: READ_WRITE
  device_name: fhm7ih5v612prt1ckhn7
  auto_delete: true
  disk_id: fhm7ih5v612prt1ckhn7
network_interfaces:
  - index: "0"
    mac_address: d0:0d:16:98:72:39
    subnet_id: e9bf5d5h0nqccfl397hu
    primary_v4_address:
      address: 10.128.0.13
      one_to_one_nat:
        address: 51.250.81.115
        ip_version: IPV4
gpu_settings: {}
fqdn: postgreshw9.ru-central1.internal
scheduling_policy: {}
network_settings:
  type: STANDARD
placement_policy: {}

/***********************************************/