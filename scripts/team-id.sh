#!/bin/zsh
# Prints the team ID of the first valid Apple Development signing identity in
# the keychain, or nothing if there isn't one.
hash=$(security find-identity -v -p codesigning | awk '/"Apple Development/ { print $2; exit }')
[[ -z "$hash" ]] && exit 0

security find-certificate -a -c "Apple Development" -Z -p \
  | awk -v hash="$hash" '/^SHA-1 hash:/ { keep = ($3 == hash); next } /hash:/ { next } keep' \
  | openssl x509 -noout -subject -nameopt multiline 2>/dev/null \
  | awk -F'= ' '/organizationalUnitName/ { print $2; exit }'
