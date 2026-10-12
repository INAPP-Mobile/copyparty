# =============================================================================
# Railway Template: copyparty
# https://github.com/9001/copyparty
# A fast, minimal, self-contained web file server / cloud-client / cloud-drive
# in a single pure-Python package. Anonymous reads (open file sharing) +
# authenticated writes (admin account). No external DB or S3 required.
# =============================================================================
# Notes:
#   • Listens on 3923 by default (PORT). Railway's proxy targets PORT, so keep
#     PORT == copyparty -p. Bind 0.0.0.0 so the platform can reach the app.
#   • Serves a single directory (/srv) mounted as a Railway volume. All user
#     files AND copyparty state live on that one volume → full persistence.
#   • Default accounts: read for everyone (anonymous), write for `admin`.
#     Override the admin password with CP_PASS (auto-generated per deploy).
#   • TLS is terminated at the Railway edge, so the app serves plain HTTP
#     (--http-only --no-crt) inside the container.
#   • Runs as root so first boot can always create/own /srv on a fresh volume.
# =============================================================================

FROM python:3.14-slim

LABEL org.opencontainers.image.source="https://github.com/9001/copyparty"
LABEL org.opencontainers.image.template.source="https://railway.com/deploy/copyparty"

# Install the single dependency. copyparty is a self-contained package that
# serves HTTP(S)/FTP/Samba and has no external service requirements.
RUN pip install --no-cache-dir copyparty==1.20.20

# Keep copyparty state (sessions, config) on the persistent /srv volume so it
# survives rebuilds and redeploys. XDG_CONFIG_HOME redirects ~/.config/copyparty
# to /srv/state/copyparty.
ENV XDG_CONFIG_HOME=/srv/state

# Listen port — present in the container env so the HEALTHCHECK and any
# sub-process can read it. Railway proxies to this. Override per deploy if needed.
ENV PORT=3923

# Served / state directory.
RUN mkdir -p /srv/state

EXPOSE 3923

# Health = the served index at / responds (200). Port reads PORT with 3923
# fallback via CMD-SHELL.
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD python3 -c "import os,urllib.request;urllib.request.urlopen('http://127.0.0.1:%s/' % os.environ.get('PORT','3923'),timeout=6)" || exit 1

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /srv

ENTRYPOINT ["/entrypoint.sh"]

CMD []
