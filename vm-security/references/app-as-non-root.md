# Moving an app off root

A web app running as root means any bug in it is root on the box. The pattern
below moves it to its own locked user with a systemd unit. Adapt names and paths;
verify each step on the real machine.

## 1. Find out what it needs

- How it runs: `pm2 jlist`, `systemctl status`, `ps -o user,pid,cmd -C node` (or python, etc.)
- Ports: `ss -tlnp` — below 1024 needs `CAP_NET_BIND_SERVICE`
- Files it reads outside its dir: TLS keys (`/etc/letsencrypt`), sockets, uploads
- Files it writes: `grep -rnE 'writeFile|createWriteStream|mkdir' src` (or equivalent)
- Env: `.env`, plus env set by the process manager (`NODE_ENV=production`)
- Does it survive a reboot today? (PM2 with no `pm2 startup` does not.)
- How the user deploys (shell history: `git pull`, `npm run ...`)

## 2. Set up the user and copy the app

```bash
useradd --system --home-dir /opt/APP --create-home --shell /usr/sbin/nologin APP
cp -a /root/APP-src /opt/APP/app          # copy, keep the original as rollback
chown -R APP:APP /opt/APP; chmod 750 /opt/APP; chmod 600 /opt/APP/app/.env
```

TLS keys from certbot: give the group read access, not the world.

```bash
chgrp APP /etc/letsencrypt/{live,archive} /etc/letsencrypt/archive/DOMAIN/privkey*.pem
chmod 750 /etc/letsencrypt/{live,archive}
chmod 640 /etc/letsencrypt/archive/DOMAIN/privkey*.pem
```

If the app itself serves port 80 and certbot uses `standalone`, add renewal hooks
in `/etc/letsencrypt/renewal-hooks/`: `pre/` stops the app, `deploy/` re-applies
the group/mode on the new `privkey*.pem`, `post/` starts it.

## 3. systemd unit

```ini
[Service]
User=APP
Group=APP
WorkingDirectory=/opt/APP/app
Environment=NODE_ENV=production
ExecStart=/usr/bin/node src/index.js
Restart=always
RestartSec=3
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
```

Drop the capability lines if it listens on a high port behind a proxy.

## 4. Cut over with automatic rollback

```bash
pm2 stop NAME
systemctl enable --now APP; sleep 6
if systemctl is-active -q APP && ss -tlnp | grep -q ':443 '; then
  pm2 delete NAME; pm2 kill
else
  journalctl -u APP -n 30; systemctl disable --now APP; pm2 start NAME
fi
```

Check from outside (`curl -I https://DOMAIN`) and hand the user the new deploy
commands: `sudo -u APP git pull` in `/opt/APP/app`, `sudo systemctl restart APP`,
`journalctl -u APP -f`.
