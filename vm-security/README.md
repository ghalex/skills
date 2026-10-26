# vm-security

Claude Code skill to audit and harden Linux VMs (Ubuntu/Debian) over SSH.

## Install

```bash
npx skills add ghalex/skills --skill vm-security
```

## Usage

```
claude "secure my server 1.2.3.4, admin user alice"
claude "check 1.2.3.4 for anything suspicious"
```

## What it does

1. Opens one multiplexed SSH connection, which is also the rollback channel
2. Runs a **read-only audit** and triages the findings
3. Asks only what would change the result: other SSH users, tunnels, extra ports, alert webhook
4. Hardens in two passes: create and verify the admin user, then lock down
5. Verifies from a fresh connection that admin works and root/password logins are refused

## Scripts

Both scripts can be used on their own, piped over SSH:

```bash
ssh HOST 'sudo bash -s -- --known-ips 1.2.3.4,5.6.7.' < scripts/audit.sh
ssh HOST 'sudo bash -s -- --admin alice --webhook https://hooks.slack.com/...' < scripts/harden.sh
```

**harden.sh** (idempotent; `--only` / `--skip` steps)
- key-only SSH, no root, `AllowUsers`, `MaxAuthTries 3`, no forwarding
- fail2ban: sshd (24h) + recidive (1 week)
- ufw: deny in, rate-limited SSH, 80/443
- unattended security upgrades, sysctl network hardening, journald size cap
- optional SSH login alerts to Slack/Discord

**audit.sh** (read-only)
- hardening state, accounts, sudoers, SSH keys
- login history: root sessions, unknown IPs, password logins, root logins after hardening, sudo commands
- suspicious commands in shell history
- persistence: cron, timers, local systemd units, rc.local, profile scripts, MOTD, PAM, `ld.so.preload`
- processes from temp dirs or deleted binaries, fake kernel threads
- public listeners, mining-pool connections
- temp-dir executables, odd directories, unknown setuid files, `dpkg --verify`
- Docker: privileged containers, host mounts, ports that bypass ufw
- runs rkhunter or chkrootkit if they are installed
