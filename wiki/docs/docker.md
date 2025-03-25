# Docker

## Installation

Install docker:

```bash
pacman -S docker
```

Add your user to the docker group so you don't need sudo:

```bash
usermod -aG docker $USER
```

Start and enable the docker service:

```bash
systemctl start docker.service
systemctl enable docker.service
```

## Basic Commands

Pull an image:
```bash
docker pull ubuntu
```

List images:
```bash
docker images
```

Run a container:
```bash
docker run -it ubuntu
```

List running containers:
```bash
docker ps
```

List all containers (including stopped):
```bash
docker ps -a
```

Stop a container:
```bash
docker stop container_id
```

Remove a container:
```bash
docker rm container_id
```

Remove an image:
```bash
docker rmi image_name
```

## Docker Compose

Install docker-compose:

```bash
pacman -S docker-compose
```

Basic docker-compose.yml structure:

```yaml
version: '3'
services:
  web:
    image: nginx
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

Run docker-compose:
```bash
docker-compose up -d
```

Stop docker-compose:
```bash
docker-compose down
```

## IPVlan - Macvlan Networks

For some reason, running IPVlan networks on the NetworkManager daemon doesn't work. I disabled the NetworkManager and enabled systemd-networkd. Then ran:

```bash
docker network create -d ipvlan --subnet=<your subnet> --gateway=<your gateway> -o parent=<ethernet interface> my_ipvlan_name
```

To mount a container to that network through compose, you need to add it in the compose file as (alpine is used for the example):

```yaml
service:
  alpine:
    image: alpine
    container_name: alpine
    networks:
      ipvlan:
        ip4_address: 192.168.0.4 # This is the IP assigned to the container. If not included, it will grab the first available IP from the DHCP server
    restart: unless-stopped
    ports:
      - 80:80
  networks:
    ipvlan:
      external: true
```

## Cool Commands

A live resource monitor for docker containers:

```bash
docker stats
```

Find the locations of all docker containers running through compose:

```bash
docker compose ls
```

List all docker containers:

```bash
docker ps
```

Go inside a container through shell:

```bash
docker exec -it "container name/id" "entrypoint"
```

The entrypoint is basically telling the container which shell to open when entering. For most cases, it will be:

```bash
/bin/bash
/bin/zsh
bash
zsh
sh
```

Restart and recreate a container stack:

```bash
docker compose up -d --force-recreate
```

## Building

To build you need a Dockerfile. They are simple to make, but you need to inspect the app you want to package. You first need to figure what environment you need and then the sequence that Docker will build the container image. For a simple react app the following Dockerfile can be used:

```dockerfile
FROM node:23.3.0-alpine
WORKDIR /app

COPY package*.json ./
RUN npm install
RUN npm i -g serve

COPY . .

RUN npm run build

EXPOSE 3000

CMD [ "serve", "-s", "dist" ]
```

Remember to always build for both ARM architecture and x86_64.

You can either manually build both images and add them to a docker manifest:

```bash
docker build --tag image-amd:tag --platform linux/amd64 . 
docker build --tag image-arm:tag --platform linux/arm64 .
docker manifest create image:tag image-amd:tag image-arm:tag
docker manifest push image:tag
```

Or you can use buildx to automatically do everything. First you need to set up a buildx driver:

```bash
docker buildx create --name=container --driver=docker-container
```

And then run buildx with all the parameters required:

```bash
docker buildx build --tag image:tag --platform linux/arm64,linux/amd64 --builder container --push .
```

To publish images, you need a Docker account.

## Back up and migration

To move, migrate, or back up docker containers are similar processes. First commit the container's current state to an image, and then save the container image to a file. 
```bash title="~/backup"
docker commit container_name image # You can find the container name with docker stats
docker save image > image.tar
```

To load a committed image run:
```
docker image load -i image.tar
```
and the `docker run` the new image or use compose. Make sure to adjust any other settings.


You might to back up the container's volumes, and volume contents. 
You can use [ricardobranco777](https://github.com/ricardobranco777)'s bash script. This script creates a new container that mounts the volumes from the container you want to copy and archives
them in a tarball. You can use his script to also load tarball volumes to the new destination. Make the [script](https://github.com/ricardobranco777/docker-volumes.sh) executable, and run:
:::tip 
You can rename the script to something catchy and copy it (or link it) to `usr/local/bin` so you can run it 
like a normal command system-wide.
:::
```bash
chmod +x docker-volumes.sh # You can add the script to your bin folder to make it available system-wide

# TO SAVE
./docker-volumes.sh container_name save tarball_name

# TO LOAD
./docker-volumes.sh container_name load tarball_name
```

Make sure you have copied over to the new host both the container tar and the volume tar. Create the container
and then run ricardobranco777's load function. 
:::tip
If you have a docker compose stack, make sure to run this process for all containers in the stack.
:::

You can also archive the volumes manually. Create a new container, use the `--volume-from` flag, have the container archive the volume
and copy it to the host.
```bash
docker run -rm --volumes-from container_name -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /container_volume
```

Create the actual container on the next host. We will use the again another temp container that will mount the new container's
volume and extract the archive into the volume.
```bash
docker run --rm --volumes-from new_container_name -v $(pwd):/backup ubuntu bash -c "cd /container_volume && tar xvf /backup/backup.tar --strip 1"
```

