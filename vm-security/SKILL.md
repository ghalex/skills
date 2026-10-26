---
name: vm-security
description: Audit and harden a Linux VM (Ubuntu/Debian) over SSH — key-only login as one admin user, no root, fail2ban, ufw, unattended security upgrades, sysctl, journald cap, SSH login alerts — plus a read-only check for signs of compromise (login history, root logins, unknown IPs, shell history, cron/systemd persistence, odd processes, setuid files, modified package files, Docker exposure). Triggers — "secure my server", "harden this VM", "lock down ssh", "check my server for suspicious files", "was my server hacked", "audit this VM", "fail2ban and ufw on".
---

# VM Security

Two scripts do the work; this file is the procedure around them. Both live in
`scripts/` next to this file and are piped to the target over SSH, so nothing
needs to be copied to the server.

- `scripts/audit.sh` — **read-only**. Changes nothing. Prints sections and
  `[!]` findings, then a summary. ~1–4 min (`--no-verify` skips the slowest part).
- `scripts/harden.sh` — idempotent. Steps: `admin ssh fail2ban ufw updates
  sysctl journald alerts`, selectable with `--only` / `--skip`.

## Inputs to collect

- **Host IP**, and the **admin user** (ask; default the user's usual name).
- **SSH key** to use (`-i ~/.ssh/<key> -o IdentitiesOnly=yes`).
- **Known IPs** of the user — memory may have them. Passed as
  `--known-ips a,b,prefix.` so logins from elsewhere get flagged. The IP of
  whoever is connected during the audit is trusted automatically.
- Before hardening, ask only what changes the outcome:
  - other accounts that must keep SSH (deploy users, a Dokploy/CI that logs in
    as root) → `--extra-users`; if something needs **root** SSH, stop and discuss.
  - SSH tunnels needed (DB access over `ssh -L`)? → `--keep-tcp-forwarding`
  - extra public ports beyond 22/80/443 → `--allow-ports`
  - a Slack/Discord webhook for login alerts → `--webhook`

## Procedure

### 1. Connect with one multiplexed connection

ufw `limit` blocks an IP after 6 SSH connections in 30s, and every check is a
new connection. Open a master once and reuse it; it is also the rollback
channel if the ssh step goes wrong.

```bash
CM="-o ControlPath=~/.ssh/cm-%r@%h:%p"
ssh -i KEY -o IdentitiesOnly=yes $CM -o ControlMaster=yes -o ControlPersist=30m -fN USER@HOST
ssh $CM USER@HOST 'whoami; sudo -n true && echo SUDO_OK'
```

Try the admin user first, then root. If `sudo -n` fails (sudo needs a
password), you cannot run the scripts non-interactively: `scp` them over and
have the user run `! ssh -t USER@HOST 'sudo bash /tmp/audit.sh ...'` themselves.

### 2. Audit first — always, before changing anything

```bash
ssh $CM USER@HOST 'sudo bash -s -- --known-ips IPS' < scripts/audit.sh > SCRATCH/audit-HOST.txt
```

Save the output to the scratchpad and read the summary. Triage each finding for
the user — don't just paste it. Known benign findings:

| Finding | Usually means |
|---|---|
| sudoers / authorized_keys changed in last 7 days | you just set up the admin user |
| processes on replaced binaries + reboot pending | upgrades ran; reboot when convenient |
| `missing` / conffile lines from dpkg | already filtered; anything left with `5` is a real content change |
| docker.sock mounted in Traefik/Dokploy | expected for those tools |
| login from unknown IP | **ask the user** — new network, VPN, phone hotspot? |

Treat as serious, and tell the user to rebuild rather than clean: `ld.so.preload`
set, a fake kernel-thread process, processes running from `/tmp` or `/dev/shm`,
mining-pool connections, unknown setuid files or PAM modules, modified binaries
in `dpkg --verify`, `curl | sh` or `history -c` in a history file, root logins
after hardening, an unknown key in `authorized_keys`. If you see any of these, **stop**
and report — do not harden over a compromised box (the attacker keeps their access).

### 3. Check what hardening would break

From the audit: what listens publicly (`network`), what runs as root, which
Docker ports are published (they **bypass ufw** — fix in compose or a cloud
firewall, ufw can't), who logs in over SSH. State the plan in a short list and
get a yes.

### 4. Harden in two passes

If the admin user does not exist yet, create it first and **prove it works**
before anything locks root out:

```bash
ssh $CM root@HOST 'bash -s -- --admin ADMIN --only admin' < scripts/harden.sh
ssh -i KEY -o IdentitiesOnly=yes -o BatchMode=yes ADMIN@HOST 'sudo -n true && echo OK'   # fresh login
```

Then the full run as the admin user (the script refuses the ssh step if the
admin has no key or no sudo, or was created in the same run by someone else):

```bash
ssh $CM ADMIN@HOST 'sudo bash -s -- --admin ADMIN [--webhook URL] [--extra-users ...] [--keep-tcp-forwarding] [--allow-ports ...]' < scripts/harden.sh
```

### 5. Verify from a fresh connection (not the master)

```bash
ssh -i KEY -o IdentitiesOnly=yes -o BatchMode=yes ADMIN@HOST 'sudo -n true && echo ADMIN_OK'
ssh -i KEY -o IdentitiesOnly=yes -o BatchMode=yes root@HOST true          # must be denied
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password ADMIN@HOST true  # must be denied
```

If the admin login fails, roll back through the still-open master:
`ssh $CM ADMIN@HOST 'sudo rm /etc/ssh/sshd_config.d/00-hardening.conf && sudo systemctl reload ssh'`.
Last resort is the provider's web console.

Re-run the audit's `hardening` section (or the whole audit) and confirm the
findings it raised are gone. Close the master: `ssh $CM -O exit USER@HOST`.

### 6. Report

A before/after table per check, the findings that still need a human decision,
and anything the scripts can't fix (provider firewall, backups, apps running as
root). If the user keeps notes about their servers, record the host, admin
user, and what was applied.

## What harden.sh sets

| Step | Effect |
|---|---|
| admin | creates ADMIN with root's `authorized_keys`, NOPASSWD sudo (only when missing) |
| ssh | `/etc/ssh/sshd_config.d/00-hardening.conf`: no root, no passwords, publickey only, `AllowUsers`, `MaxAuthTries 3`, `LoginGraceTime 20`, no X11/agent/TCP forwarding; locks root's password |
| fail2ban | `jail.local`: sshd 5 tries/10m → 24h ban; recidive 3 bans/day → 1 week |
| ufw | deny in, allow out, `limit` SSH, allow 80/443; warns about extra rules and Docker ports, removes nothing |
| updates | unattended security upgrades daily, never auto-reboots |
| sysctl | `/etc/sysctl.d/99-vm-security.conf`: syncookies, no redirects/source routes, loose rp_filter, kptr/dmesg restrict. Leaves `ip_forward` alone (Docker) |
| journald | `SystemMaxUse=500M` |
| alerts | `pam_exec` hook posts every SSH login to the webhook (Slack `text` / Discord `content`); optional, never blocks a login |

Files it replaces that it didn't write are backed up as `*.bak-<timestamp>`.

## Gotchas

- `MaxAuthTries 3`: a client with many keys in its agent gets "Too many
  authentication failures" — always connect with `-o IdentitiesOnly=yes`.
- Never close the only working session until a fresh admin login is verified.
- Docker-published ports ignore ufw. Bind them to `127.0.0.1` or put them behind the reverse proxy.
- If a platform (Dokploy remote servers, Ansible, CI) logs in as root, `AllowUsers` +
  `PermitRootLogin no` breaks it. Ask before hardening such a box.
- An app running as root is the bigger risk after SSH. See
  `references/app-as-non-root.md` for moving it to a dedicated user.
- The audit reads `/etc/shadow` and history files but prints only flagged
  lines, never whole histories (they often contain secrets).
