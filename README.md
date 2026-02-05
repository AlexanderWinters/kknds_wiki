My wiki page developed with [Docusaurus](https://docusaurus.io/). 

Check it out at [wiki.kknds.com](https://wiki.kknds.com)

# Build and Deploy

```bash
git pull
cd wiki 
npm run build 
```
I use systemd to deploy, but you can use your favorite middleware/deployment. Here is my `wiki.service` stored in `/etc/systemd/system`:

```bash
[Unit]
Description=The Wiki
After=network.target

[Service]
Type=simple
User=your_user
WorkingDirectory=/path/to/repo/kknds_wiki/wiki
Environment=NODE_ENV=production
Environment=PORT=6969
ExecStart=/usr/bin/npm run serve --no-open
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```
