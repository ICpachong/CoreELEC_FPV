#!/bin/sh

# Reachability rescue for wired links (built-in MAC or USB NIC).
#
# Symptoms seen in the field: connman ends up with a 169.254.x.x link-local
# address (DHCP gave up) and the box becomes unreachable over SSH, even
# though a manually configured static IP works fine. With a slow-to-start
# DHCP server (Windows ICS on 192.168.137.1) connman can also stop its
# autoconnect cycle while retrying a carrier-less interface.
#
# Strategy:
#   1. while a wired interface only has a 169.254 address, toggle carrier
#      (ip link down/up) so connman re-runs DHCP, several attempts.
#   2. probe with busybox udhcpc directly: if it gets a lease we keep the
#      address alive ourselves (and the log shows connman was at fault);
#      if it does not, the DHCP server/network side is the problem.
#   3. if everything above failed and a static fallback is explicitly
#      configured, apply it and keep refreshing it, because connman flushes
#      foreign addresses on carrier events.
#
# Override via /storage/.config/network-rescue.conf, e.g.
#   STATIC_IP=...      -> enable the static fallback address/prefix
#   STATIC_GW=...      -> fallback gateway (default: 192.168.137.1)
# The static fallback is disabled unless STATIC_IP is set.

STATIC_IP="${STATIC_IP:-}"
STATIC_GW="${STATIC_GW:-192.168.137.1}"
ATTEMPTS="${ATTEMPTS:-6}"
[ -f /storage/.config/network-rescue.conf ] && . /storage/.config/network-rescue.conf

log() { echo "network-rescue: $*" >/dev/kmsg; }

wired_iface() {
  for d in /sys/class/net/*; do
    n="${d##*/}"
    [ "$n" = "lo" ] && continue
    [ -e "$d/wireless" ] && continue
    grep -q 1 "$d/carrier" 2>/dev/null || continue
    echo "$n"
    return 0
  done
  return 1
}

has_routable_ipv4() {
  ip -o addr show dev "$1" 2>/dev/null | grep "inet " | grep -vqE "169\.254\.|127\."
}

has_link_local() {
  ip -o addr show dev "$1" 2>/dev/null | grep "inet " | grep -q "169\.254\."
}

# udhcpc writes lease details here via the helper script below
LEASE_FILE=/tmp/network-rescue.lease

cat > /tmp/udhcpc-rescue.script <<'EOF'
#!/bin/sh
[ "$1" = "bound" ] || [ "$1" = "renew" ] || exit 0
{
  echo "iface=$interface"
  echo "ip=$ip"
  echo "mask=${mask:-255.255.255.0}"
  echo "router=$router"
  echo "dns=$dns"
} > /tmp/network-rescue.lease
EOF
chmod +x /tmp/udhcpc-rescue.script

mask2cidr() {
  bits=0
  IFS=.
  for octet in $1; do
    case "$octet" in
      255) bits=$((bits + 8)) ;;
      254) bits=$((bits + 7)) ; break ;;
      252) bits=$((bits + 6)) ; break ;;
      248) bits=$((bits + 5)) ; break ;;
      240) bits=$((bits + 4)) ; break ;;
      224) bits=$((bits + 3)) ; break ;;
      192) bits=$((bits + 2)) ; break ;;
      128) bits=$((bits + 1)) ; break ;;
      *)   break ;;
    esac
  done
  unset IFS
  echo "$bits"
}

# connman keeps gateway-less default/host routes around while its DHCP client
# is failing; they shadow the real gateway and break off-link traffic and DNS.
# Only drop routes without gateway and without a source address, so the
# kernel-maintained connected routes stay in place.
drop_stray_routes() {
  ip route show dev "$1" 2>/dev/null | grep -v ' via ' | grep -v ' src ' |
    awk '{print $1}' | while read -r net; do
      [ -n "$net" ] && ip route del "$net" dev "$1" 2>/dev/null
    done
}

apply_lease() {
  # $1=iface $2=ip/mask $3=gw $4=dns (space separated)
  ip addr flush dev "$1" 2>/dev/null
  drop_stray_routes "$1"
  ip addr add "$2" dev "$1"
  ip link set "$1" up
  [ -n "$3" ] && ip route replace default via "$3" dev "$1"
  if [ -n "$4" ]; then
    : > /run/connman/resolv.conf
    for n in $4; do echo "nameserver $n" >> /run/connman/resolv.conf; done
  else
    printf 'nameserver 223.5.5.5\n' > /run/connman/resolv.conf
  fi
}

apply_static() {
  ip addr flush dev "$iface" 2>/dev/null
  drop_stray_routes "$iface"
  ip addr add "$STATIC_IP" dev "$iface"
  ip link set "$iface" up
  if [ -n "$STATIC_GW" ]; then
    ip route replace default via "$STATIC_GW" dev "$iface"
    printf 'nameserver %s\nnameserver 223.5.5.5\n' "$STATIC_GW" > /run/connman/resolv.conf 2>/dev/null
  else
    printf 'nameserver 223.5.5.5\n' > /run/connman/resolv.conf 2>/dev/null
  fi
}

iface=""
for i in $(seq 1 36); do
  iface=$(wired_iface) && break
  sleep 5
done
[ -n "$iface" ] || { log "no wired interface with carrier, exiting"; exit 0; }
log "watching $iface"

sleep 15   # give connman a first DHCP round to finish on its own

i=0
while [ $i -lt "$ATTEMPTS" ]; do
  if has_routable_ipv4 "$iface"; then
    log "$iface has a routable address, done"
    exit 0
  fi
  if has_link_local "$iface"; then
    i=$((i + 1))
    log "$iface stuck on link-local, forcing DHCP retry $i/$ATTEMPTS"
    ip link set "$iface" down
    sleep 2
    ip link set "$iface" up
  fi
  sleep 12
done

if has_routable_ipv4 "$iface"; then
  log "$iface recovered via DHCP, done"
  exit 0
fi

# connman did not manage: probe with our own DHCP client to tell connman
# faults apart from a dead DHCP server, and grab a lease if one is offered.
log "connman DHCP failed, probing with udhcpc on $iface"
rm -f $LEASE_FILE
udhcpc -n -q -t 8 -T 3 -i "$iface" -s /tmp/udhcpc-rescue.script \
       -p /var/run/udhcpc.rescue.pid >/dev/null 2>&1
if [ -f $LEASE_FILE ]; then
  . $LEASE_FILE
  log "udhcpc got lease $ip/$mask gw=$router (connman was the problem), keeping it alive"
  apply_lease "$iface" "$ip/$(mask2cidr "$mask")" "$router" "$dns"
  # keep refreshing: connman may flush this foreign address on carrier events
  while :; do
    sleep 30
    ip -o addr show dev "$iface" 2>/dev/null | grep -q "inet $ip/" && continue
    log "udhcpc address disappeared, re-probing"
    rm -f $LEASE_FILE
    udhcpc -n -q -t 8 -T 3 -i "$iface" -s /tmp/udhcpc-rescue.script >/dev/null 2>&1
    if [ -f $LEASE_FILE ]; then
      . $LEASE_FILE
      apply_lease "$iface" "$ip/$(mask2cidr "$mask")" "$router" "$dns"
    fi
  done
fi
log "udhcpc got no lease either - DHCP server not answering"

[ -n "$STATIC_IP" ] || { log "static fallback disabled"; exit 0; }

log "applying static $STATIC_IP (gw=${STATIC_GW:-none})"
apply_static
log "static configuration applied on $iface, refreshing every 30s"

while :; do
  sleep 30
  drop_stray_routes "$iface"
  if ip -o addr show dev "$iface" 2>/dev/null | grep "inet " | grep -q "$(echo "$STATIC_IP" | cut -d/ -f1)"; then
    if [ -n "$STATIC_GW" ] && ! ip route show default 2>/dev/null | grep -q "via $STATIC_GW"; then
      log "default route missing, reapplying static"
      apply_static
    fi
    continue
  fi
  if has_routable_ipv4 "$iface"; then
    log "$iface got a dynamic address, stopping rescue loop"
    [ -n "$STATIC_GW" ] && ip route del default via "$STATIC_GW" dev "$iface" 2>/dev/null
    exit 0
  fi
  log "static address disappeared, reapplying"
  apply_static
done
