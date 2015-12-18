#!/bin/bash

# Creates a SOCKS5 proxy that routes traffic through any SSH server
# LTH servers are used by default

SSH_PORT="22"
PROXY_PORT="10203"
USER="dat13ebj"
HOST="login.student.lth.se"

ssh -p $SSH_PORT -D $PROXY_PORT $USER@$HOST
# Found in guide:
#   http://wiki.vpslink.com/Instant_SOCKS_Proxy_over_SSH#Linux
# Also has instructions for equivalent functionality with PuTTY in Windows
# Put in background by adding the '-f' flag

# Test the proxy with:
#   curl --socks5 localhost:10203 myip.se
# You should see that the IP given is the LU IP, and the ISP should be Lund University.

# Use this command to verify that the proxy is running.
#   netstat -tlnp | grep $PROXY_PORT

