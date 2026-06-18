# Gitea Maintenance
## Preparation

- no one using the servers
- storages are nominal (nothing exceeds 60%)
- hardware usage is nominal (no weird spikes on CPU, and RAM is not full)
- check network traffic

## Back up

- start deleting old repos (current retention is 3 years)
- run a backup from onion to rocky. This will probably take a full day.

## Update 

- `docker compose pull`
- `docker compose up -d`
- Make sure everything is working.