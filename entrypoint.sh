#!/bin/sh
# copyparty — Railway template entrypoint.
# Serves the /srv volume: anonymous read (open sharing) + admin write.
set -e

# Ensure the served directory and the state directory exist on the volume.
mkdir -p /srv /srv/state

# Put copyparty's on-disk state (sessions / config) on the persistent volume.
export XDG_CONFIG_HOME=/srv/state

# Listen port (Railway proxies to PORT). Keep in sync with EXPOSE/Dockerfile.
PORT="${PORT:-3923}"
export PORT

# Admin account for writes. CP_PASS defaults to a safe literal if left unset;
# the template deploy form generates a per-instance secret via ${{secret(32)}}.
CP_PASS="${CP_PASS:-wark}"

# Volume permission model (copyparty --help-accounts grammar "src:dst:perm..."):
#   .::r          -> mount current dir (=/srv, via --chdir) at root "/" with
#                   read (list + download) for EVERYONE (anonymous) — open sharing
#   A,admin       -> all perms (read/write/move/delete/admin/dotfiles) for `admin`
# Net effect: any visitor with the link can browse & download (no login);
# only the `admin` account can upload/delete/rename. This is the safe default
# for a PUBLIC file server — anonymous never gets write/delete.
exec python3 -m copyparty \
  --chdir /srv \
  -a "admin:${CP_PASS}" \
  -v ".::r:A,admin" \
  -i 0.0.0.0 \
  -p "$PORT" \
  --http-only \
  --no-crt \
  --no-thumb
