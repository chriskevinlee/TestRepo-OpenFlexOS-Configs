#!/usr/bin/env bash

STATE_FILE="$HOME/.ip_script_index"

functions=(
  get_router_ip
  get_local_ip
  get_public_ip
  get_hostname
)
get_router_ip() {
    echo "Router IP: $(ip route get 1.1.1.1 | awk '/via/ {print $3; exit}')"
}
get_local_ip() {
    echo "Local IP: $(ip route get 1.1.1.1 | awk '/via/ {print $7; exit}')"
}

get_public_ip() {
    echo "Public IP: $(curl -4s icanhazip.com)"
}

get_hostname() {
    echo "Hostname: $(cat /etc/hostname)"
}

index=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
max=$(( ${#functions[@]} - 1 ))

while getopts "np" opt; do
  case "$opt" in
    n)
      ((index++))
      (( index > max )) && index=0
      ;;
    p)
      ((index--))
      (( index < 0 )) && index=$max
      ;;
  esac
done

"${functions[index]}"
echo "$index" > "$STATE_FILE"
