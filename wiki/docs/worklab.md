# Worklab

## Gitea
Gitea is a backend git server, similar to github and gitlab but open source. I run it on a docker container so portability is rather straight forward but does require some setting up when restoring. 

### Back up

Before anything, you might want to login to the gitea container as `root` and give permissions to the `git` user for the `tmp` folder so the git user can write in it:

```plaintext
docker exec -it gitea bash
chown git:git /tmp
```

Log into the Gitea container as the `git` user (or the user you defined as the main user for git):

```plaintext
docker exec -u git -it gitea bash
```

Then run the dump command, exluding all the repositories and logs. We will backup the repositories manually:

```plaintext
/app/gitea/gitea dump --skip-repository --skip-log
```

You can override the default write folder (which is `/tmp`) by adding the `--file` flag and the path. Make sure you give write permissions to the git user.

Log out of the container and copy the dump into the host:

```plaintext
docker cp gitea:/tmp/gitea_dump111.zip /path/to/host
```

Bring down the container and now backup the repositories with your favorite archiving tool. The repositories should be in `/gitea/git` unless you manually changed the path. I use `tar` to archive and compress:

```plaintext
tar -czf gitea_archive.tar.gz ./gitea/git
```

My live environment has about 2TB of repositories so it took a full day to finish archiving and moving to different location.

### Restore

Start the docker container for the first time, set it up and let it install. Bring down the container and copy over the repositories. This will probably take some time.

Unzip the gitea dump. Bring up the containers, and copy the database dump into the database container, not the gitea container.

```plaintext
docker cp gitea-db.sql gitea-db:/tmp
```

Log into the database container, and restore the database. You might need to reset the database, and you will probably need to force restore.

I use mysql for the database; if you use another tool, please refer to their docs for resetting and restoring. To reset the database in the database container start mysql and run the following:

```plaintext
mysql -uroot -p<ROOT_PASSWORD>
DROP DATABASE IF EXISTS gitea; 
CREATE DATABASE gitea CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_0900_as_cs'; 
GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'; 
FLUSH PRIVILEGES; 
exit
```

Time to restore. Depending on the size of your environment this can take between minutes and days. If you have a big environment, maybe it's a good idea to run the restore on the background and with `nohup` active so you can logout of the container and do other things:

```plaintext
nohup mysql -u<GITEA_USERNAME> -p<GITEA_PASSWORD> -f -D gitea < gitea-db.sql &
```

The usernames and passwords are the ones you have defined in the `docker-compose.yml` file.

## Backing up and restoring Jira WIP

I had to move my Jira instance from a windows server to a container.

FIrst you need to find the versions that your license supports. Before taking down your old Jira instance, export all the data, and tar all files associated with Jira. Once done, you can take down the old Jira instance. 

After running the docker container successfully, start Jira.

-   Select “I will set up myself”
-   Connect the container's database (you can find the details in the docker compose file)
-   When asked to set up license or new user, instead select ‘import from old instance’. This button is a little obsured, but it should come up right after the database set up.
-   Back on your host terminal, copy the exported data .zip into the jira container's import folder:

```plaintext
docker cp jira_30243453.zip jira_container:/var/atlassian/application-data/jira/import/
```

-   And then in the Jira website, right the path of the .zip and import.

This should import all your settings, users and the license and you should be able to login with the credentials from the old Jira instance.

## Reverse Proxy

I use NGINX to forward all traffic. To make sure HTTPS works, we need to generate self-signed SSL certificates.

1\. create a 2048-bit RSA private key:

```plaintext
openssl genrsa -out server.key 2048
```

2\. create a self-signed request. You need to fill the prompts. If you want to leave something empty use ‘.’:

```plaintext
openssl req -new -key server.key -out server.csr
```

3\. create the SSL certificate. You can adjust the expiration date of the SSL certificate here. Best practice is to the update them every year (365 days):

```plaintext
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

4\. test the certificate:

```plaintext
openssl x509 -in server.crt -text -noout
```

You can optionally combine the key and certificate into one file; sometimes useful for some web servers:

```plaintext
cat server.crt server.key > server.pem
```

You can either use an NGINX docker container or the NGINX daemon. For the daemon, you can create your configurations in `/etc/nginx/sites-available/my.conf`. Example conf for a service on localhost:8080:

```plaintext
server {
    listen 443 ssl;
    server_name your_domain_or_ip;

    ssl_certificate /path/to/your/fullchain.pem;
    ssl_certificate_key /path/to/your/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}

server {
    listen 80;
    server_name your_domain_or_ip;
    return 301 https://$host$request_uri;
}
```

Replace  `your_domain_or_ip` and the correct paths to the SSL certificates and keys. Enable then the new nginx conf:

```plaintext
sudo ln -s /etc/nginx/sites-available/jira.conf /etc/nginx/sites-enabled/
sudo nginx -t   # Check for syntax errors
sudo systemctl restart nginx
```