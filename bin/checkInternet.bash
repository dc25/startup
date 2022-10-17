#! /bin/bash

# thanks to : https://unix.stackexchange.com/a/190610/332667

test=google.com
if nc -zw1 $test 443 && echo |openssl s_client -connect $test:443 2>&1 |awk '
  handshake && $1 == "Verification" { if ($2=="OK") exit; exit 1 }
  $1 $2 == "SSLhandshake" { handshake = 1 }'
then
  : echo "connectivity"
else
  echo "NO connectivity"
fi
