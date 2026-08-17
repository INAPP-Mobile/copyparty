# Deploy and Host

[![Deploy to Railway](https://railway.app/button.svg)](https://railway.com/deploy/copyparty-1)

copyparty is a fast, minimal, self-contained web file server, cloud-client, and cloud-drive in a **single pure-Python package**. It serves files over HTTP, FTP, and Samba — with a modern web UI for browsing, uploading, and sharing — and needs no external database or object storage. Anonymous visitors get **read-only** access (open file sharing); the `admin` account gets **write** access (upload, delete, rename). Deploy it on Railway in minutes.

## About Hosting

copyparty runs as a single Docker container on port `3923`. Railway provides compute, TLS at the edge (the app serves plain HTTP inside the container), and a public URL. All user files and copyparty state live at `/srv` — mount a Railway Volume there so your files survive restarts and redeploys. No Postgres, Redis, or S3 required.

## Why Deploy

- **Open file sharing** — anonymous read access: anyone with the link can browse and download, no login needed
- **Authenticated writes** — `admin` account (password = `CP_PASS`) uploads, deletes, renames, and manages
- **One package, zero services** — self-contained; serves HTTP/HTTPS, FTP, and Samba from the same process
- **Small footprint** — installs in seconds on slim Python; a few dozen MB of RAM at idle
- **Fast** — written for low latency, zero-copy file streaming
- **Share links** — per-file/per-folder access via the web control panel
- **Web DA** — modern control-panel UI with drag-and-drop upload
- **Multi-protocol** — browse in the browser, or connect with `curl` / `scp`-style tools / SMB clients

## Common Use Cases

- **Drop-style file sharing** — publish a folder, get a public link to browse/download
- **Lightweight personal drive** — self-contained, no S3 bill; files live on a Railway volume
- **Backup handoff** — grab files from a running container via the web UI or FTP
- **Temporary staging** — expose a directory during dev/ops, then take the service down

## Dependencies for copyparty

### Deployment Dependencies

copyparty is a standalone service that requires **no external dependencies** on Railway. It uses its own on-disk state and the files you serve — both live on the single volume mounted at `/srv`. Add one Railway Volume there for persistence.

---

# copyparty — self-contained web file server & cloud drive

> A fast, minimal, pure-Python file server, cloud-client, and cloud-drive. Serve over HTTP/FTP/Samba with a modern web UI. No external services.

## Features

- **Anonymous read / admin write** — out-of-the-box open sharing; uploads require the `admin` account
- **Self-contained** — single `pip install copyparty`, no external DB or object store
- **Web control panel** — modern UI with drag-and-drop upload and file manager
- **Multi-protocol** — HTTP, FTP, and Samba served from the same process (enable Samba when you mount it)
- **Fast transfer** — zero-copy streaming, low-latency listing
- **Share links** — per-folder / per-file public links from the control panel
- **Small image** — `python:3.12-slim` + one package
- **Healthcheck built in** — Docker `HEALTHCHECK` polls the served index

## Architecture

```
┌──────────────────────────┐      ┌────────────────────┐
│      Client              │      │   copyparty        │
│  (browser / curl /       │─────►│   (on Railway)     │
│   FTP / SMB / rsync)     │ HTTP │   Port 3923        │
└──────────────────────────┘      │   /srv (volume)    │
                                  │   /srv/state       │
                                  └────────────────────┘
```

One container, one volume. Anonymous clients read; the `admin` account writes. TLS is terminated at the Railway edge — the app serves plain HTTP inside.

## Environment Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `PORT` | `3923` | ✅ | Port Railway proxies to. Must equal copyparty's `-p` (leave default). |
| `CP_PASS` | — | ✅ | Password for the `admin` account (used for uploads / writes / management). Auto-generated per deploy via `${{secret(32)}}`; find it under your Railway service variables after deploy. |

## Volumes

| Mount | Description |
|-------|-------------|
| `/srv` | User files you want to serve, **and** copyparty's on-disk state (`/srv/state`). One volume, both read + write + persistence. |

Add a Railway Volume at `/srv` to keep your files and session state across restarts and redeploys.

## Default Admin Credentials

> ⚠️ **SECURITY** — the `admin` account's password is set from the deploy form variable `CP_PASS`. If you ever see the fallback `wark` in a log, that's the literal default in the entrypoint and **must** be overridden by the `CP_PASS` deploy variable (which is auto-generated per instance). Anonymous clients stay read-only regardless of the admin password.

## How to Use

1. Click the **Deploy to Railway** button above
2. The deploy form auto-generates `CP_PASS` (a random 32-char secret) — keep it somewhere safe; you'll need it for uploads
3. Add a Railway Volume at `/srv` (the template pre-selects this)
4. Once deployed, open your Railway URL — you'll get a browsable web file manager
5. Read-only access works out of the box for any anonymous visitor
6. To upload, click "log in" in the control panel and use `admin` + your `CP_PASS` value (Service → Variables → `CP_PASS`)
7. Optional: open FTP or Samba from inside the container if you need those protocols (enable by mounting the corresponding services)
