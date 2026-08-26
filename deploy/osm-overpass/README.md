# Self-hosted OSM (Overpass API) replica

Replaces the public Overpass mirrors that the relocation-candidate-search pipeline hammers for
amenity counts (cafes, bookshops, galleries, occult shops, …). Two regional Overpass instances,
deployed via Coolify on **PiHost**.

## Why this shape (decisions, with the evidence)

- **Option A (Overpass), not osm2pgsql/PostGIS.** The pipeline calls Overpass; this is the
  direct replacement. SQL access wasn't needed.
- **Regional init, not planet clone.** PiHost is a Raspberry Pi 4 (8GB RAM, arm64), and the
  RAID1 mirror is ~1.8TB. A ~1.5TB planet clone won't sit comfortably beside the existing
  Nextcloud data, and serving a planet Overpass on a Pi's USB-attached spinning disks isn't
  realistic. Regional extracts (US 11GB pbf, Britain & Ireland 2.4GB pbf) fit easily.
- **Two instances (US + Britain & Ireland).** One Overpass instance = one `.pbf`. The towns are
  US + UK + IE, so two extracts, two containers, two ports.
- **Data on `/mnt/raid1`, not the root SSD.** The root is a scarce 120GB USB SSD; the OSM DBs
  (US ~40–60GB, GB/IE ~10–15GB imported) go on the mirror via **bind mounts**, exactly as
  Nextcloud does on this host.
- **Ingress through Coolify's Traefik proxy — no published host ports.** Publishing raw container
  ports would bypass Traefik, which is not how anything on this host is deployed. Each service
  `expose`s port 80 and gets a domain via Coolify's `SERVICE_FQDN_*` magic env var; Coolify wires
  the Traefik router. Plain HTTP on :80 with sslip.io hostnames, matching Fizzy/Nextcloud — this
  host is LAN-only and can't get a Let's Encrypt cert via HTTP-01, so there is no :443. The two
  instances serve identical paths, so they're told apart by **hostname**.
- **`wiktorn/overpass-api:latest` runs on arm64.** Confirmed the image publishes an arm64
  manifest variant before committing to Option A.
- **Init from `.pbf` needs the preprocess hook (this image assumes `.bz2`).** The image's importer
  (`init_osm3s.sh`) hardcodes `bunzip2 <planet.osm.bz2 | update_database`, expecting a real
  `.osm.bz2`. Geofabrik retired `.bz2` for these regions (only `.osm.pbf` remains — verified the
  `.bz2` URLs 404), and the download is always saved as `/db/planet.osm.bz2` regardless of real
  format. `OVERPASS_PLANET_PREPROCESS` is the image's hook to **massage the downloaded file before
  the importer runs** — so both services use it to transcode the pbf into a genuine bzip2 in place:
  `osmium cat -F pbf /db/planet.osm.bz2 -f osm.bz2 -o /db/planet.converted.osm.bz2 && mv -f …`.
  Then the stock `init_osm3s.sh` does its own `mkdir -p /db/db` + `bunzip2 | update_database`
  unchanged. `-F pbf` is required so osmium reads the (mislabeled `.bz2`) file as pbf; `-f osm.bz2`
  makes it write a real bzip2 the importer can bunzip2. Validated 2026-08-23 end-to-end (transcode
  → `bunzip2 -t` OK → `update_database` produces `nodes.map`), and confirmed live on PiHost.
  - **Prior bug (fixed 2026-08-23 — do not reintroduce).** The hook originally ran
    `update_database --db-dir=/db/db …` *directly*, treating the preprocess step as the importer.
    That failed on **every** boot with `No such file or directory /db/db/nodes.map`: the hook runs
    *before* `init_osm3s.sh` creates `/db/db`, and `init_osm3s.sh` then still ran and re-failed
    trying to `bunzip2` the pbf. The container crash-looped, **re-downloading the whole extract each
    cycle** (GB/IE failed 21×, US 4× — ~12 GB re-fetched per US loop). The fix stops fighting the
    entrypoint: massage the file, let the image import it.
- **Daily updates, Coolify-managed.** Per your call ("Coolify must manage the container"), the
  update loop is **internal** to each container (`OVERPASS_UPDATE_SLEEP=86400` = 24h). A host cron
  running `docker exec` was rejected: Coolify recreates containers on deploy, which would break
  any out-of-band host cron bound to a container name. Geofabrik publishes these regional diffs
  daily, so 24h matches the feed's grain — one small diff per cycle. The image persists its
  `replicate_id` on the mirror and walks forward to Geofabrik's latest each cycle, so a missed
  day (container down) self-heals on the next run. Verified 2026-08-23 that the diff paths the
  image computes (`state.txt` + `NNN/NNN/NNN.osc.gz`) resolve against both `us-updates/` and
  `britain-and-ireland-updates/`.
- **Single-user tuning.** You're the only caller, so `OVERPASS_FASTCGI_PROCESSES=2` — enough for
  a sequential pipeline, and it saves RAM on the 8GB Pi.

## Host prerequisites (already done on PiHost 2026-08-23)

Bind-mount dirs pre-created on the mirror, world-writable so the image's root entrypoint can
populate and `chown /db` on first init:

```bash
sudo mkdir -p /mnt/raid1/osm/us_db /mnt/raid1/osm/gb_ie_db
sudo chmod 777 /mnt/raid1/osm/us_db /mnt/raid1/osm/gb_ie_db
```

The `wiktorn/overpass-api:latest` image is already pulled on the host.

## Deploy

1. In Coolify → the target project → **+ New Resource → Docker Compose**, paste
   `docker-compose.yml` from this directory.
2. Deploy. **First boot imports from Geofabrik** — hours on this host's USB spinning mirror.
   The API returns errors until the import completes; the healthcheck's long `start_period`
   accounts for this.
3. **Consider staggering the two first imports.** Importing US and GB/IE simultaneously doubles
   the RAM/IO pressure on the 8GB Pi. If the box struggles, deploy `overpass-gbie` first, let it
   finish importing, then bring up `overpass-us`. Steady-state (post-import) query load is light.

Endpoints (via Traefik, plain HTTP on :80):

| Instance | Region | Endpoint |
|---|---|---|
| `overpass-us`   | US                | `http://osm-us.10.0.0.233.sslip.io/api/interpreter` |
| `overpass-gbie` | Britain & Ireland | `http://osm-gbie.10.0.0.233.sslip.io/api/interpreter` |

> Reachable only on TheOutlands LAN (PiHost is not internet-exposed). `*.10.0.0.233.sslip.io`
> resolves to `10.0.0.233` with no DNS setup, matching the Fizzy convention on this host.
> If Coolify's `SERVICE_FQDN_*` handling doesn't emit the router on this version, set the domain
> per service in the Coolify UI instead (Fizzy's labels were generated that way) — same result.

## Verify

```bash
# Base data timestamp (proves the import finished and updates are current):
curl -s 'http://osm-us.10.0.0.233.sslip.io/api/interpreter?data=[out:json];node(1);out;' | jq -r .osm3s.timestamp_osm_base
curl -s 'http://osm-gbie.10.0.0.233.sslip.io/api/interpreter?data=[out:json];node(1);out;' | jq -r .osm3s.timestamp_osm_base
```

A timestamp within a few days of now = healthy and updating. No timestamp / errors = still
importing (or import failed — check `sudo docker logs overpass-us`).

## Wire the pipeline

The relocation pipeline lives outside this repo (hermes / `scripts/enrich.py`, the `enrich_osm`
pass). Point its Overpass calls at the two instances by region — US towns →
`http://osm-us.10.0.0.233.sslip.io/api/interpreter`, UK/IE towns →
`http://osm-gbie.10.0.0.233.sslip.io/api/interpreter` — instead of the public mirrors.

## Caveats to remember

- **Data dir must stay on `/mnt/raid1`.** Never let Coolify relocate `/db` to a managed volume
  on the root SSD — same footgun the host docs call out for Nextcloud.
- **Hot-unplugging a mirror disk can take PiHost down** (shared xHCI USB bus). Not specific to
  this stack, but the DBs live on that mirror.
- **First import is long and IO-heavy.** Don't mistake a still-importing instance for a broken
  one; check the logs and the `start_period`.
