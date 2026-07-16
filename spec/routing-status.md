# CloudBeaver on HeLx — Status & Subpath-Routing Issue

Status: **launches and serves UI; GraphQL/WS API blocked by an upstream subpath bug**
Owner: jseals
Last updated: 2026-07-16
Related: appstore `spec/ambassador-removal.md` (the routing effort this feeds into)

## 1. What this image is

HeLx's CloudBeaver image (`containers.renci.org/helxplatform/third-party/cloudbeaver`)
wraps the upstream `dbeaver/cloudbeaver` server so it can run as a HeLx app:

- launched by Tycho as a ClusterIP service `cloudbeaver-{guid}`, reached at
  `/private/cloudbeaver/{user}/{guid}/…` (see the ambassador-removal spec);
- runs **as root** (HeLx sets `TYCHO_APP_RUN_AS_USER=0`) and writes its workspace
  under `/opt/cloudbeaver`;
- authenticates via CloudBeaver's **reverse-proxy** provider, trusting the
  `REMOTE_USER` header that appstore/resty inject (`.cloudbeaver.runtime.conf`).

Current version: **`1.0.1`** (`Makefile VERSION`), built `--platform linux/amd64`
from `FROM dbeaver/cloudbeaver:latest`.

## 2. Current state (2026-07-16, helx-internal)

- ✅ Image builds and pushes (`1.0.1`, digest `sha256:62e0a4…`).
- ✅ Pod starts cleanly — **no "Unable to create lock manager"** (see §4.1).
- ✅ Static app loads: `GET /private/cloudbeaver/{user}/{guid}/` → 200, assets +
  favicons + manifest all serve at the single prefix.
- ✅ Auth chain reaches the app (`REMOTE_USER` reverse-proxy provider configured).
- ❌ **GraphQL API fails**: the browser POSTs to `…/{guid}/api/gql` and gets **405**;
  the frontend surfaces this as a JS error and the UI cannot load data.
- ❌ **"No websocket mappings"** logged — the event/WS channel has the same defect.

## 3. Root cause — upstream subpath regression in the latest base

CloudBeaver is hosted at a **subpath** (`rootURI = /private/cloudbeaver/{user}/{guid}`),
not at the domain root. On the latest `dbeaver/cloudbeaver` base the server applies
`rootURI` **inconsistently** between the two kinds of servlet:

| Servlet | Mapping registered (from startup log) | In context `…/{guid}` | Effective path |
|---|---|---|---|
| static  | `[/]` (relative) | ✅ | `…/{guid}/` (single — correct) |
| graphql | `[…/{guid}/api/gql/*]` (**absolute, already contains `rootURI`**) | ✅ | `…/{guid}/…/{guid}/api/gql` (**doubled**) |

The Jetty `ServletContextHandler` context path **is** `rootURI`, and the API servlet
mappings **also** contain `rootURI`, so the API mounts one prefix too deep. Static
servlets are mapped relative (`/`) so they land correctly. The frontend, meanwhile,
derives its API URL from the **single** prefix, so it targets the wrong place.

### Evidence (curl directly inside the pod, bypassing resty)

```
POST …/{guid}/api/gql                 -> 405   # frontend targets here (static DefaultServlet answers)
GET  …/{guid}/api/gql                 -> 404
POST …/{guid}/{guid-doubled}/api/gql  -> 200   # where the servlet actually mounted
```

### Why no env value fixes it

`rootURI` / `serviceURI` are the only knobs (`conf/cloudbeaver.conf`), and they are a
**single coupled knob**:

- The frontend reads `_ROOT_URI_`, which the server substitutes into `web/index.html`
  from `rootURI` **per request** (the on-disk file holds the literal `{ROOT_URI}`
  placeholder). Frontend URLs are therefore `rootURI + /api/gql`.
- Setting `rootURI = /` makes the server mount the API at a single (root) prefix, but
  then the frontend emits **root-absolute** `/api/gql`, which the browser sends
  **without** the `/private/cloudbeaver/{user}/{guid}` prefix → resty can't attribute
  it to this app.
- Setting `rootURI = {prefix}` makes the frontend target correctly but doubles the
  server API mount (the observed bug).

So there is no `rootURI`/`serviceURI` combination that keeps the frontend prefix and
the server API mount aligned. This is an upstream defect, not a HeLx routing problem —
static, auth, and page load all work.

## 4. Fixes already applied in this image

### 4.1 "Unable to create lock manager" (fixed)

The latest base renamed the launcher to `launch-product.sh`, which — when run as
root — `su`'s to the unprivileged `dbeaver` user (uid 8978). HeLx `chown`s
`/opt/cloudbeaver` to `cloudbeaver` (uid 8979), so the `su`'d `dbeaver` user can't
write the OSGi config/lock area. **Fix:** `helx/helx-init.sh` calls the inner
`./run-cloudbeaver-server.sh` directly so it runs as root (as the old `run-server.sh`
did). — this is the `1.0.0 → 1.0.1` change.

### 4.2 Double-slash servlet paths / `contextPath ends with /` (fixed)

`CLOUDBEAVER_ROOT_URI` must **not** have a trailing slash (`NB_PREFIX` has none). A
trailing slash made `serviceURI` resolve to `<prefix>//api/` and Jetty warn. Fixed in
`helx-init.sh` (`export CLOUDBEAVER_ROOT_URI="$NB_PREFIX"`).

### 4.3 Migration to the latest base

`Dockerfile` now `FROM dbeaver/cloudbeaver:latest`, adds
`CLOUDBEAVER_APP_FORWARD_PROXY=true`, seeds admin creds, and `chmod +x` all
`helx-init-scripts`. `Makefile` builds `--platform linux/amd64` and tags both the
RENCI registry and a personal Docker Hub repo.

## 5. Options to close out the API-routing bug (not yet chosen)

1. **Pin an older base** that maps API servlets relative (subpath hosting worked in
   the version behind the old `0.0.19` image). Keeps appstore/resty generic; loses
   "latest".
2. **resty prefix-double** for cloudbeaver only: proxy `…/{guid}/api/*` to the backend
   as `…/{guid}/{guid-prefix}/api/*` (proven to return 200). Fast, but hardcodes one
   app's quirk into the shared data plane.
3. **Image-level patch**: run the server at `rootURI=/` (single mount) while forcing
   the served `_ROOT_URI_` to the real prefix and having resty **strip** the prefix
   for cloudbeaver. Keeps latest + generic resty, but several fragile moving parts.
4. **Upstream**: file/track a `dbeaver/cloudbeaver` issue — API servlet mappings
   should be relative to the `rootURI` context, not absolute.

## 6. Key files

| File | Role |
|---|---|
| `Dockerfile` | `FROM dbeaver/cloudbeaver:latest`; runs as `cloudbeaver`; entrypoint `helx-init.sh` |
| `helx/helx-init.sh` | sets `CLOUDBEAVER_ROOT_URI=$NB_PREFIX`; runs `run-cloudbeaver-server.sh` as root |
| `helx/helx-init-scripts/09-cloudconf.sh` | copies `.cloudbeaver.runtime.conf` into the workspace |
| `helx/helx-init-scripts/10-user.sh` | HeLx user/home setup (keeps default home) |
| `helx/cloudconf/.cloudbeaver.runtime.conf` | server config: `reverseProxy` auth on `REMOTE_USER`, quotas, anonymous team |
| `Makefile` | `VERSION`, `build` (amd64), `push` (RENCI), `personal-push` (Docker Hub) |

## 7. How to build & test

```
make build          # linux/amd64, tags RENCI + personal + local
make push           # -> containers.renci.org/helxplatform/third-party/cloudbeaver:$(VERSION)
```

Then set the app-spec image (helx-apps `ambassador_removal` branch,
`app-specs/cloudbeaver/docker-compose.yaml`) to the new tag, restart appstore, relaunch.
Use a **new** version tag each build — Tycho pods use `imagePullPolicy: IfNotPresent`,
so reusing a tag serves the cached old image.
