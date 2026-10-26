#!/usr/bin/env bash
# vm-security / audit.sh — READ-ONLY security check for Ubuntu/Debian VMs.
# It changes nothing on the machine (only a temp file, removed on exit).
#
# Run as root on the target, e.g. from your laptop:
#   ssh HOST 'sudo bash -s -- --known-ips 79.119.231.60,188.25.59.' < audit.sh
#
# Options:
#   --known-ips a,b   your IPs or prefixes; logins from anything else are flagged
#   --days N          how far back to read logs (default 30)
#   --no-verify       skip dpkg --verify (the slowest check)
#
# Every finding worth a look is printed as "[!]" and repeated in the summary.
set -uo pipefail

KNOWN_IPS=""
DAYS=30
VERIFY=1
while [ $# -gt 0 ]; do
  case "$1" in
    --known-ips) KNOWN_IPS="$2"; shift 2 ;;
    --days) DAYS="$2"; shift 2 ;;
    --no-verify) VERIFY=0; shift ;;
    -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" = 0 ] || { echo "run as root (sudo) for a full audit" >&2; exit 1; }

# Findings go to a temp file: most are raised inside piped loops (subshells).
FLAGFILE=$(mktemp)
trap 'rm -f "$FLAGFILE" "$FLAGFILE.del"' EXIT
CUR=""
section() { CUR="$1"; echo; echo "=== $1 ==="; }
flag()    { echo "[$CUR] $*" >> "$FLAGFILE"; echo "  [!] $*"; }
info()    { echo "  $*"; }
indent()  { sed 's/^/    /'; }

known_ip() {
  [ -z "$KNOWN_IPS" ] && return 0
  local p
  for p in ${KNOWN_IPS//,/ }; do case "$1" in "$p"*) return 0 ;; esac; done
  return 1
}

SINCE="-${DAYS}d"

# Whoever is connected over SSH right now (e.g. you) counts as known.
CUR_IPS=$(ss -tnH state established '( sport = :22 )' 2>/dev/null | awk '{print $4}' | sed -E 's/:[0-9]+$//; s/^\[//; s/\]$//; s/^::ffff://' | sort -u | tr '\n' ',')
KNOWN_IPS="${KNOWN_IPS:+$KNOWN_IPS,}${CUR_IPS%,}"
SUSPECT_CMD='(curl|wget)[^|;]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|base64[[:space:]]+(-d|--decode)|/dev/tcp/|nc[[:space:]].*-e[[:space:]]|chmod[[:space:]]+\+?[0-7x+]*[[:space:]]+/(tmp|dev/shm|var/tmp)|xmrig|minerd|cryptonight|stratum\+tcp|history[[:space:]]+-c|unset[[:space:]]+HISTFILE|HISTSIZE=0|HISTFILE=/dev/null'

# Login homes: root + every user with a real shell or uid >= 1000.
HOMES=$(awk -F: '$1=="root" || $3>=1000 && $7 !~ /(nologin|false)$/ {print $1":"$6}' /etc/passwd)

# ================================================================ system
section "system"
info "host: $(hostname)  |  $(. /etc/os-release; echo "$PRETTY_NAME")  |  kernel $(uname -r)"
info "uptime: $(uptime -p)"
[ -f /var/run/reboot-required ] && flag "reboot pending (kernel/libc updates not active yet)"
sec=$(apt list --upgradable 2>/dev/null | grep -c -- '-security')
[ "$sec" -gt 0 ] && flag "$sec security updates waiting to be installed"

# ================================================================ hardening state
section "hardening"
eff=$(sshd -T 2>/dev/null)
echo "$eff" | grep -Ei '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|authenticationmethods|allowusers|maxauthtries|allowtcpforwarding) ' | indent
echo "$eff" | grep -q '^permitrootlogin no' || flag "root can log in over SSH"
echo "$eff" | grep -q '^passwordauthentication yes' && flag "SSH password login is enabled"
echo "$eff" | grep -q '^kbdinteractiveauthentication yes' && flag "SSH keyboard-interactive login is enabled"
echo "$eff" | grep -q '^allowusers' || flag "no AllowUsers — any account with a key can log in"
akf=$(echo "$eff" | awk '/^authorizedkeysfile /{$1=""; print}')
case "$akf" in *".ssh/authorized_keys"*) ;; *) flag "non-standard AuthorizedKeysFile:$akf" ;; esac

if command -v ufw >/dev/null 2>&1 && ufw status | grep -q 'Status: active'; then
  info "ufw: active"
  ufw status | awk 'NR>4 && NF' | indent
else
  flag "ufw is not active"
fi
if systemctl is-active -q fail2ban 2>/dev/null; then
  info "fail2ban: $(fail2ban-client status 2>/dev/null | awk -F: '/Jail list/{print $2}')"
else
  flag "fail2ban is not running"
fi
apt-config dump 2>/dev/null | grep -q 'APT::Periodic::Unattended-Upgrade "1"' \
  && info "unattended-upgrades: on" || flag "unattended security upgrades are off"

# ================================================================ accounts
section "accounts"
awk -F: '$3==0 && $1!="root" {print $1}' /etc/passwd | while read -r u; do flag "extra UID 0 account: $u"; done
info "accounts with a login shell:"
awk -F: '$7 !~ /(nologin|false|sync|halt|shutdown)$/ {print $1" (uid "$3", "$7")"}' /etc/passwd | indent
awk -F: '$2=="" {print $1}' /etc/shadow | while read -r u; do flag "account with EMPTY password: $u"; done
awk -F: '$2 ~ /^\$/ {print $1}' /etc/shadow | while read -r u; do
  [ "$u" = root ] && flag "root has a usable password (lock it: passwd -l root)" || info "has a password: $u"
done
info "sudo group: $(getent group sudo | cut -d: -f4)"
for f in /etc/sudoers /etc/sudoers.d/*; do
  [ -f "$f" ] || continue
  grep -vE '^\s*(#|$|Defaults)' "$f" | sed "s|^|$(basename "$f"): |" | indent
done
find /etc/sudoers.d -type f -newermt "-7 days" 2>/dev/null | while read -r f; do flag "sudoers file changed in last 7 days: $f"; done

# ================================================================ ssh keys
section "ssh keys"
echo "$HOMES" | while IFS=: read -r u h; do
  for f in "$h/.ssh/authorized_keys" "$h/.ssh/authorized_keys2"; do
    [ -f "$f" ] || continue
    info "$f  (modified $(date -r "$f" '+%F %R'))"
    ssh-keygen -lf "$f" 2>/dev/null | indent
    case "$f" in *keys2) flag "legacy authorized_keys2 exists: $f" ;; esac
    [ -n "$(find "$f" -newermt '-7 days' 2>/dev/null)" ] && flag "$f changed in the last 7 days"
    grep -qE '^(command|environment)=' "$f" && flag "$f has forced command/environment options"
  done
done

# ================================================================ logins
section "logins (last $DAYS days)"
info "logged in now:"; who | indent
info "recent sessions:"; last -wi -n 15 2>/dev/null | grep -v '^$' | indent
root_last=$(last -wi root 2>/dev/null | grep -vE '^$|^wtmp' | head -10)
if [ -n "$root_last" ]; then
  info "root sessions (wtmp):"; echo "$root_last" | indent
fi
hard=/etc/ssh/sshd_config.d/00-hardening.conf

authlog=$(journalctl -u ssh -u sshd --since "$SINCE" -o short-iso --no-pager 2>/dev/null)
[ -z "$authlog" ] && [ -f /var/log/auth.log ] && authlog=$(cat /var/log/auth.log)
accepted=$(echo "$authlog" | grep -E 'Accepted (publickey|password|keyboard-interactive)')
info "accepted SSH logins (count user ip method):"
echo "$accepted" | sed -nE 's/.*Accepted ([a-z-]+) for ([^ ]+) from ([^ ]+).*/\2 \3 \1/p' \
  | sort | uniq -c | sort -rn | indent
echo "$accepted" | sed -nE 's/.*Accepted ([a-z-]+) for ([^ ]+) from ([^ ]+).*/\2 \3 \1/p' | sort -u \
  | while read -r u ip m; do
      [ "$m" != publickey ] && flag "$m login accepted: $u from $ip"
      known_ip "$ip" || flag "login from unknown IP: $u from $ip"
    done
if [ -f "$hard" ]; then
  since_h=$(date -r "$hard" '+%Y-%m-%dT%H:%M:%S')
  echo "$authlog" | awk -v t="$since_h" '$1 >= t' | grep -E 'Accepted [a-z-]+ for root ' \
    | while read -r l; do flag "root login AFTER hardening: $l"; done
fi
fails=$(echo "$authlog" | grep -cE 'Failed password|Invalid user|authentication failure')
info "failed/invalid attempts: $fails  — top sources:"
echo "$authlog" | grep -oE '(Failed password|Invalid user).* from [0-9a-fA-F:.]+' | grep -oE '[0-9a-fA-F:.]+$' \
  | sort | uniq -c | sort -rn | head -8 | indent
info "sudo commands (latest 20):"
journalctl _COMM=sudo --since "$SINCE" -o short-iso --no-pager 2>/dev/null | grep 'COMMAND=' \
  | sed -E 's/^([^ ]+) [^ ]+ sudo\[[0-9]+\]: +/\1 /; s/ : (TTY|PWD)=[^;]*;//g' | cut -c1-180 | tail -20 | indent

# ================================================================ shell history
section "shell history"
echo "$HOMES" | while IFS=: read -r u h; do
  for f in "$h/.bash_history" "$h/.zsh_history" "$h/.sh_history"; do
    if [ -L "$f" ]; then flag "$f is a symlink to $(readlink "$f") (history hidden)"; continue; fi
    [ -f "$f" ] || continue
    info "$f  ($(wc -l < "$f") lines, modified $(date -r "$f" '+%F %R'))"
    grep -nE "$SUSPECT_CMD" "$f" 2>/dev/null | cut -c1-200 | while read -r l; do flag "$f:$l"; done
  done
  for rc in "$h/.bashrc" "$h/.profile" "$h/.bash_profile" "$h/.zshrc"; do
    [ -f "$rc" ] && grep -nE 'HISTFILE=/dev/null|unset HISTFILE|HISTSIZE=0|curl |wget |/dev/tcp/|base64 ' "$rc" 2>/dev/null \
      | cut -c1-200 | while read -r l; do flag "$rc:$l"; done
  done
done

# ================================================================ persistence
section "persistence"
[ -s /etc/ld.so.preload ] && flag "/etc/ld.so.preload is set (classic rootkit trick): $(tr '\n' ' ' < /etc/ld.so.preload)"
info "cron entries:"
for f in /etc/crontab /etc/cron.d/* /var/spool/cron/crontabs/*; do
  [ -f "$f" ] || continue
  grep -vE '^\s*(#|$)|^[A-Z_]+=' "$f" | sed "s|^|$f: |" | cut -c1-200 | indent
  grep -nE 'curl|wget|base64|/tmp/|/dev/shm|/var/tmp|bash -c|python[0-9]* -c|nohup' "$f" 2>/dev/null \
    | cut -c1-200 | while read -r l; do flag "suspicious cron: $f:$l"; done
done
info "timers:"; systemctl list-timers --all --no-pager --no-legend 2>/dev/null | awk '{print $(NF-1), $NF}' | indent

info "local systemd units (not from a package):"
for f in /etc/systemd/system/*.service /etc/systemd/system/*.timer; do
  [ -f "$f" ] && [ ! -L "$f" ] || continue
  dpkg -S "$f" >/dev/null 2>&1 && continue
  ex=$(grep -hE '^\s*Exec(Start|StartPre)=' "$f" | head -1 | cut -c1-150)
  info "  $(basename "$f")  [$(date -r "$f" '+%F')]  $ex"
  echo "$ex" | grep -qE '/tmp/|/dev/shm|/var/tmp|/\.[^/]+/|curl|wget|base64' && flag "unit runs from a suspicious place: $f"
done
for d in /root/.config/systemd/user /home/*/.config/systemd/user; do
  [ -d "$d" ] && [ -n "$(ls -A "$d" 2>/dev/null)" ] && flag "user-level systemd units in $d: $(ls "$d" | tr '\n' ' ')"
done
if [ -f /etc/rc.local ] && grep -qvE '^\s*(#|$|exit 0)' /etc/rc.local; then
  flag "/etc/rc.local has commands:"; grep -vE '^\s*(#|$)' /etc/rc.local | indent
fi
for f in /etc/profile /etc/profile.d/* /etc/bash.bashrc /etc/environment; do
  [ -f "$f" ] && grep -nE 'curl |wget |/dev/tcp/|base64 |nohup |LD_PRELOAD' "$f" 2>/dev/null \
    | cut -c1-200 | while read -r l; do flag "login script: $f:$l"; done
done
find /etc/update-motd.d -type f -newermt "$SINCE" 2>/dev/null | while read -r f; do flag "MOTD script changed recently: $f"; done
pamdir=$(dirname "$(find /lib /usr/lib -name pam_unix.so 2>/dev/null | head -1)" 2>/dev/null)
if [ -n "$pamdir" ] && [ -d "$pamdir" ]; then
  # shellcheck disable=SC2046
  dpkg -S $(ls "$pamdir"/*.so) 2>&1 >/dev/null | grep -oE '/[^ ]+\.so' | while read -r m; do flag "PAM module not from a package: $m"; done
fi
grep -hE 'pam_exec' /etc/pam.d/* 2>/dev/null | grep -v vm-login-alert | while read -r l; do flag "pam_exec hook: $l"; done

# ================================================================ processes
section "processes"
info "top CPU:"; ps -eo user,pid,pcpu,pmem,etime,comm --sort=-pcpu | head -8 | indent
for p in /proc/[0-9]*; do
  pid=${p#/proc/}
  exe=$(readlink "$p/exe" 2>/dev/null) || continue
  cmd=$(tr '\0' ' ' < "$p/cmdline" 2>/dev/null | cut -c1-120)
  case "$exe" in
    /tmp/*|/var/tmp/*|/dev/shm/*) flag "process $pid runs from $exe ($cmd)" ;;
    *" (deleted)") echo "$pid $exe" >> "$FLAGFILE.del" ;;
  esac
  case "$cmd" in "["*) flag "process $pid pretends to be a kernel thread: '$cmd' -> $exe" ;; esac
done

if [ -s "$FLAGFILE.del" ]; then
  n=$(wc -l < "$FLAGFILE.del")
  if [ -f /var/run/reboot-required ]; then
    info "$n processes run binaries replaced by upgrades (reboot pending — expected):"
    awk '{print $2}' "$FLAGFILE.del" | sort | uniq -c | indent
  else
    flag "$n processes run deleted binaries with no pending reboot:"
    indent < "$FLAGFILE.del"
  fi
  rm -f "$FLAGFILE.del"
fi

# ================================================================ network
section "network"
info "listening:"; ss -tulpnH 2>/dev/null | awk '{print $1, $5, $7}' | indent
ss -tlnpH 2>/dev/null | awk '{print $4, $6}' | grep -E '^(0\.0\.0\.0|\*|\[::\]):' \
  | grep -vE '^[^ ]+:(22|80|443) ' | while read -r a pr; do flag "public listener on $a $pr"; done
info "established outbound:"
ss -tnpH state established 2>/dev/null | awk '{print $4, $5, $6}' | grep -vE '127\.0\.0\.1|\[::1\]' \
  | awk '{split($1,l,":"); if (l[length(l)] != 22) print}' | head -25 | indent
ss -tnH state established 2>/dev/null | awk '{print $4}' | grep -E ':(3333|4444|5555|7777|8888|9999|14433|14444|45560|45700)$' \
  | while read -r r; do flag "connection to a common mining-pool port: $r"; done

# ================================================================ files
section "files"
find /tmp /var/tmp /dev/shm -xdev \( -path '*/systemd-private-*' -o -path '*/snap-private-tmp*' \) -prune \
  -o -type f \( -perm -u+x -o -name '.*' \) -print 2>/dev/null | head -20 \
  | while read -r f; do flag "executable/hidden file in temp: $f"; done
find / -xdev \( -path /proc -o -path /sys -o -path /var/lib/docker -o -path /snap -o -path /var/lib/containerd \) -prune \
  -o -type d \( -name '...' -o -name '.. *' -o -name '. *' -o -name ' *' \) -print 2>/dev/null | head -10 \
  | while read -r d; do flag "oddly named directory: '$d'"; done
suid=$(find / -xdev \( -path /proc -o -path /var/lib/docker -o -path /snap -o -path /var/lib/containerd \) -prune \
  -o -type f \( -perm -4000 -o -perm -2000 \) -print 2>/dev/null)
for f in $suid; do
  alt=$(echo "$f" | sed -E 's#^/usr/(s?bin|lib)/#/\1/#')   # merged-/usr: dpkg may list /bin/x for /usr/bin/x
  dpkg -S "$f" >/dev/null 2>&1 || dpkg -S "$alt" >/dev/null 2>&1 || flag "setuid/setgid file not from a package: $f"
done
info "changed in last 7 days under /usr/bin /usr/sbin /usr/lib/systemd /etc/systemd (top 15):"
find /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin /usr/lib/systemd /etc/systemd -xdev -type f -newermt '-7 days' 2>/dev/null \
  | head -15 | indent
find /usr/local/bin /usr/local/sbin -type f 2>/dev/null | head -20 | while read -r f; do info "local binary: $f"; done
find /etc /usr -xdev -type f -perm -0002 2>/dev/null | head -10 | while read -r f; do flag "world-writable system file: $f"; done
if [ "$VERIFY" = 1 ]; then
  info "dpkg --verify (package files changed on disk, config files excluded)..."
  dpkg --verify 2>/dev/null | grep -E '^..5' | grep -vE '^[^ ]+ +c ' | head -20 | while read -r l; do flag "package file modified: $l"; done
fi

# ================================================================ docker
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  section "docker"
  docker ps -a --format '{{.Names}} | {{.Image}} | {{.Status}} | {{.Ports}}' | cut -c1-200 | indent
  docker ps -q | while read -r c; do
    n=$(docker inspect -f '{{.Name}}' "$c" | tr -d /)
    [ "$(docker inspect -f '{{.HostConfig.Privileged}}' "$c")" = true ] && flag "privileged container: $n"
    docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' "$c" | tr ' ' '\n' | grep -qx '/' && flag "container mounts host /: $n"
    docker inspect -f '{{range .Mounts}}{{.Source}} {{end}}' "$c" | grep -q docker.sock && info "mounts docker.sock (ok for Traefik/Dokploy, else suspicious): $n"
  done
  docker ps --format '{{.Names}} {{.Ports}}' | grep -E '0\.0\.0\.0:|\[::\]:' | grep -vE '0\.0\.0\.0:(80|443)->' \
    | while read -r l; do flag "Docker-published port bypasses ufw: $l"; done
fi

# ================================================================ rootkit scanners
section "rootkit scanners"
if command -v rkhunter >/dev/null 2>&1; then
  rkhunter --check --sk --rwo --nocolors 2>/dev/null | head -20 | while read -r l; do flag "rkhunter: $l"; done
else info "rkhunter not installed (optional: apt install rkhunter)"; fi
if command -v chkrootkit >/dev/null 2>&1; then
  chkrootkit -q 2>/dev/null | head -20 | while read -r l; do flag "chkrootkit: $l"; done
else info "chkrootkit not installed (optional)"; fi

# ================================================================ summary
echo
echo "=== SUMMARY: $(wc -l < "$FLAGFILE") finding(s) on $(hostname) ==="
sed 's/^/  /' "$FLAGFILE"
[ -s "$FLAGFILE" ] || echo "  nothing suspicious found"
exit 0
