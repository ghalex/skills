#!/usr/bin/env bash
# vm-security / harden.sh — idempotent hardening for Ubuntu/Debian VMs.
#
# Run as root on the target, e.g. from your laptop:
#   ssh HOST 'sudo bash -s -- --admin alice' < harden.sh
#
# Steps (all on by default, pick with --only / --skip):
#   admin     create the admin user from root's authorized_keys if missing
#   ssh       key-only, no root, AllowUsers, tighter sshd limits
#   fail2ban  sshd jail (24h) + recidive jail (1 week for repeat offenders)
#   ufw       deny in, allow out, limit SSH, allow 80/443 (+ --allow-ports)
#   updates   unattended security upgrades (no auto-reboot)
#   sysctl    kernel/network hardening (Docker-safe)
#   journald  cap journal size at 500M
#   alerts    SSH login alerts to a Slack/Discord webhook (needs --webhook)
set -uo pipefail

ADMIN=""
EXTRA_USERS=""
WEBHOOK=""
ALLOW_PORTS=""
KEEP_FWD=0
ONLY=""
SKIP=""
MANAGED="# managed by vm-security harden.sh"

usage() {
  sed -n '2,17p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'
  cat <<EOF

Options:
  --admin USER            admin user allowed to SSH in (required)
  --extra-users "a b"     more users to keep in AllowUsers (e.g. a deploy user)
  --allow-ports 8080,9000 extra TCP ports to open in ufw
  --keep-tcp-forwarding   keep AllowTcpForwarding yes (needed for SSH tunnels)
  --webhook URL           Slack/Discord webhook for login alerts
  --only a,b              run only these steps
  --skip a,b              skip these steps
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --admin) ADMIN="$2"; shift 2 ;;
    --extra-users) EXTRA_USERS="$2"; shift 2 ;;
    --allow-ports) ALLOW_PORTS="$2"; shift 2 ;;
    --keep-tcp-forwarding) KEEP_FWD=1; shift ;;
    --webhook) WEBHOOK="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --skip) SKIP="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

die()  { echo "  FAIL: $*" >&2; exit 1; }
step() { echo; echo "==> $1"; }
ok()   { echo "  ok: $*"; }
warn() { echo "  WARN: $*"; }

[ "$(id -u)" = 0 ] || die "run as root (sudo)"
[ -n "$ADMIN" ] || { usage; die "--admin USER is required"; }

want() {
  case ",$SKIP," in *",$1,"*) return 1 ;; esac
  [ -z "$ONLY" ] && return 0
  case ",$ONLY," in *",$1,"*) return 0 ;; esac
  return 1
}

# Back up a file we did not write before replacing it.
backup() {
  [ -f "$1" ] || return 0
  grep -qF "$MANAGED" "$1" && return 0
  cp -a "$1" "$1.bak-$(date +%Y%m%d%H%M%S)"
  warn "backed up existing $1"
}

export DEBIAN_FRONTEND=noninteractive
APT_UPDATED=0
apt_install() {
  local need=""
  for p in "$@"; do dpkg -s "$p" >/dev/null 2>&1 || need="$need $p"; done
  [ -z "$need" ] && return 0
  if [ "$APT_UPDATED" = 0 ]; then apt-get update -qq >/dev/null; APT_UPDATED=1; fi
  # shellcheck disable=SC2086
  apt-get install -y -qq $need >/dev/null || die "apt install failed:$need"
  ok "installed$need"
}

SSH_PORT=$(sshd -T 2>/dev/null | awk '/^port /{print $2; exit}')
SSH_PORT=${SSH_PORT:-22}
ADMIN_CREATED=0

# ---------------------------------------------------------------- admin
if want admin; then
  step "admin user: $ADMIN"
  if ! id "$ADMIN" >/dev/null 2>&1; then
    src=""
    for f in /root/.ssh/authorized_keys ${SUDO_USER:+"/home/$SUDO_USER/.ssh/authorized_keys"}; do
      [ -s "$f" ] && { src="$f"; break; }
    done
    [ -n "$src" ] || die "no authorized_keys found to give the new user"
    adduser --disabled-password --gecos "" "$ADMIN" >/dev/null
    home=$(getent passwd "$ADMIN" | cut -d: -f6)
    install -d -m 700 -o "$ADMIN" -g "$ADMIN" "$home/.ssh"
    install -m 600 -o "$ADMIN" -g "$ADMIN" "$src" "$home/.ssh/authorized_keys"
    usermod -aG sudo "$ADMIN"
    echo "$ADMIN ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$ADMIN"
    chmod 440 "/etc/sudoers.d/90-$ADMIN"
    visudo -cq || { rm -f "/etc/sudoers.d/90-$ADMIN"; die "sudoers check failed"; }
    ADMIN_CREATED=1
    ok "created $ADMIN (keys from $src, NOPASSWD sudo)"
  else
    ok "$ADMIN exists"
  fi
fi

# ---------------------------------------------------------------- ssh
if want ssh; then
  step "sshd"
  home=$(getent passwd "$ADMIN" | cut -d: -f6)
  if ! id "$ADMIN" >/dev/null 2>&1; then
    warn "$ADMIN does not exist — skipping ssh step (would lock you out)"
  elif [ ! -s "$home/.ssh/authorized_keys" ]; then
    warn "$ADMIN has no authorized_keys — skipping ssh step (would lock you out)"
  elif ! sudo -l -U "$ADMIN" 2>/dev/null | grep -q "may run"; then
    warn "$ADMIN has no sudo — skipping ssh step (root login is the only way to admin)"
  elif [ "$ADMIN_CREATED" = 1 ] && [ "${SUDO_USER:-root}" != "$ADMIN" ]; then
    warn "$ADMIN was just created — verify 'ssh $ADMIN@host' + sudo works, then re-run"
  elif ! grep -qE '^\s*Include\s+/etc/ssh/sshd_config.d/' /etc/ssh/sshd_config; then
    warn "sshd_config has no Include for sshd_config.d — skipping, fix manually"
  else
    fwd=no; [ "$KEEP_FWD" = 1 ] && fwd=yes
    conf=/etc/ssh/sshd_config.d/00-hardening.conf
    backup "$conf"
    cat > "$conf" <<EOF
$MANAGED
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
AuthenticationMethods publickey
AllowUsers $ADMIN${EXTRA_USERS:+ $EXTRA_USERS}
MaxAuthTries 3
LoginGraceTime 20
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding $fwd
EOF
    if ! sshd -t; then
      rm -f "$conf"; die "sshd config test failed — removed $conf"
    fi
    systemctl reload ssh 2>/dev/null || systemctl reload sshd || die "sshd reload failed"
    eff=$(sshd -T 2>/dev/null)
    echo "$eff" | grep -q '^permitrootlogin no' || warn "PermitRootLogin not 'no' after reload"
    echo "$eff" | grep -q '^passwordauthentication no' || warn "PasswordAuthentication still on"
    passwd -S root 2>/dev/null | awk '{print $2}' | grep -q '^L' || { passwd -l root >/dev/null; ok "locked root password"; }
    ok "key-only, root off, AllowUsers $ADMIN${EXTRA_USERS:+ $EXTRA_USERS}, TcpForwarding=$fwd"
    echo "  >> test a FRESH login now from your laptop before closing this session"
  fi
fi

# ---------------------------------------------------------------- fail2ban
if want fail2ban; then
  step "fail2ban"
  apt_install fail2ban
  backup /etc/fail2ban/jail.local
  cat > /etc/fail2ban/jail.local <<EOF
$MANAGED
[DEFAULT]
bantime  = 24h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled = true
port    = $SSH_PORT

[recidive]
enabled  = true
backend  = auto
logpath  = /var/log/fail2ban.log
bantime  = 1w
findtime = 1d
maxretry = 3
EOF
  touch /var/log/fail2ban.log
  systemctl enable fail2ban >/dev/null 2>&1
  systemctl restart fail2ban || die "fail2ban failed to start"
  sleep 2
  fail2ban-client status 2>/dev/null | grep -q sshd && ok "jails: sshd (24h), recidive (1w)" || warn "sshd jail not running"
fi

# ---------------------------------------------------------------- ufw
if want ufw; then
  step "ufw"
  apt_install ufw
  ufw default deny incoming >/dev/null
  ufw default allow outgoing >/dev/null
  ufw delete allow "$SSH_PORT/tcp" >/dev/null 2>&1
  ufw limit "$SSH_PORT/tcp" >/dev/null
  ufw allow 80/tcp >/dev/null
  ufw allow 443/tcp >/dev/null
  for p in ${ALLOW_PORTS//,/ }; do ufw allow "$p/tcp" >/dev/null; done
  ufw --force enable >/dev/null
  ok "deny in; limit $SSH_PORT; allow 80,443${ALLOW_PORTS:+,$ALLOW_PORTS}"
  extra=$(ufw status | awk 'NR>4 && $1 !~ /^('"$SSH_PORT"'|80|443)(\/tcp)?$/' | grep -vE "^(${ALLOW_PORTS//,/|})(/tcp)? " | grep -v '^$')
  [ -n "$extra" ] && { warn "other ufw rules exist (left alone):"; echo "$extra" | sed 's/^/    /'; }
  if command -v docker >/dev/null 2>&1; then
    pub=$(docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null | grep -E '0\.0\.0\.0:|\[::\]:' )
    [ -n "$pub" ] && { warn "Docker-published ports BYPASS ufw:"; echo "$pub" | sed 's/^/    /'; }
  fi
fi

# ---------------------------------------------------------------- updates
if want updates; then
  step "unattended security upgrades"
  apt_install unattended-upgrades
  cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
$MANAGED
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
  ok "daily security upgrades, no automatic reboot"
  [ -f /var/run/reboot-required ] && warn "a reboot is pending (/var/run/reboot-required)"
fi

# ---------------------------------------------------------------- sysctl
if want sysctl; then
  step "sysctl"
  # ip_forward is deliberately untouched (Docker needs it); rp_filter=2 (loose) is Docker-safe.
  cat > /etc/sysctl.d/99-vm-security.conf <<EOF
$MANAGED
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
fs.suid_dumpable = 0
EOF
  sysctl -q --system >/dev/null 2>&1 || warn "some sysctl keys failed to apply"
  ok "applied /etc/sysctl.d/99-vm-security.conf"
fi

# ---------------------------------------------------------------- journald
if want journald; then
  step "journald"
  install -d /etc/systemd/journald.conf.d
  cat > /etc/systemd/journald.conf.d/99-vm-security.conf <<EOF
$MANAGED
[Journal]
SystemMaxUse=500M
EOF
  systemctl restart systemd-journald
  ok "journal capped at 500M"
fi

# ---------------------------------------------------------------- alerts
if want alerts; then
  step "SSH login alerts"
  if [ -z "$WEBHOOK" ]; then
    ok "skipped (no --webhook)"
  else
    apt_install curl
    install -d -m 700 /etc/vm-security
    printf 'ALERT_WEBHOOK=%s\n' "$WEBHOOK" > /etc/vm-security/alert.env
    chmod 600 /etc/vm-security/alert.env
    cat > /usr/local/sbin/vm-login-alert <<'EOF'
#!/bin/sh
# managed by vm-security harden.sh — called by pam_exec on SSH session open.
[ "$PAM_TYPE" = "open_session" ] || exit 0
. /etc/vm-security/alert.env
[ -n "$ALERT_WEBHOOK" ] || exit 0
msg="SSH login: ${PAM_USER} from ${PAM_RHOST:-?} on $(hostname) at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
key=text; case "$ALERT_WEBHOOK" in *discord*) key=content ;; esac
curl -fsS -m 5 -H 'Content-Type: application/json' \
  --data "{\"$key\":\"$msg\"}" "$ALERT_WEBHOOK" >/dev/null 2>&1 &
exit 0
EOF
    chmod 755 /usr/local/sbin/vm-login-alert
    line="session optional pam_exec.so quiet /usr/local/sbin/vm-login-alert"
    grep -qF "/usr/local/sbin/vm-login-alert" /etc/pam.d/sshd || echo "$line" >> /etc/pam.d/sshd
    key=text; case "$WEBHOOK" in *discord*) key=content ;; esac
    curl -fsS -m 5 -H 'Content-Type: application/json' \
      --data "{\"$key\":\"vm-security: login alerts enabled on $(hostname)\"}" "$WEBHOOK" >/dev/null \
      && ok "alerts on — test message sent" || warn "webhook test failed; check the URL"
  fi
fi

# ---------------------------------------------------------------- summary
step "summary"
sshd -T 2>/dev/null | grep -Ei '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|maxauthtries|allowtcpforwarding) ' | sed 's/^/  /'
echo "  ufw: $(ufw status 2>/dev/null | head -1)"
echo "  fail2ban: $(systemctl is-active fail2ban 2>/dev/null)"
