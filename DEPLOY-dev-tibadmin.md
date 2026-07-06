# Esporre `rio` su `dev.tibadmin.xyz`

Documento di riferimento per pubblicare l'applicazione **rio** sul sottodominio
`dev.tibadmin.xyz`, mantenendo **konnex** su `tibadmin.xyz`.

---

## 1. Situazione attuale (rilevata sul server)

- **Un solo server**: IPv4 `91.99.152.94`, IPv6 `2a01:4f8:c013:d47a::1`.
- Gira lo stack **konnex in modalità `dev`** (container `konnex_dev_*`).
- Il container **`konnex_dev_nginx` occupa le porte 80/443** ed è l'**unico terminatore TLS**
  (monta `/etc/letsencrypt` in sola lettura). Serve `tibadmin.xyz`.
- **`rio` NON è in esecuzione.** Il suo frontend ha un nginx interno che ascolta in
  **HTTP sulla porta 5173** (pubblicata sull'host), con `server_name _`.
- **Il certificato attuale copre SOLO `tibadmin.xyz`** — non è wildcard, non copre `www`,
  `flower`, ecc. (`SAN = DNS:tibadmin.xyz`, scadenza 7 lug 2026).

### Conseguenza fondamentale

Solo **un** processo può tenere le porte 80/443, e oggi è l'nginx di konnex.
Quindi `rio` **non può** ascoltare direttamente sulla 443: la 443 è già occupata.
Il traffico per `dev.tibadmin.xyz` deve **passare attraverso l'nginx di konnex**, che fa
da **reverse proxy** e inoltra a rio. Questo vale per tutte le opzioni qui sotto.

```
                                  ┌──────────────────────────────────────┐
   Internet  ──443──►  konnex_dev_nginx  ──┬─► tibadmin.xyz      → konnex
   (TLS qui)                               └─► dev.tibadmin.xyz  → rio (5173, HTTP)
                                  └──────────────────────────────────────┘
```

---

## 2. Passi comuni a TUTTE le opzioni

Questi vanno fatti in ogni caso, indipendentemente dall'opzione di collegamento scelta.

### 2.1 DNS su Hetzner (lo fai nel pannello DNS, zona `tibadmin.xyz`)

| Tipo   | Nome  | Valore                       |
|--------|-------|------------------------------|
| `A`    | `dev` | `91.99.152.94`               |
| `AAAA` | `dev` | `2a01:4f8:c013:d47a::1` (opz.) |

### 2.2 Certificato TLS

Il cert attuale **non** copre `dev.tibadmin.xyz`. Va esteso. Vedi le due varianti
al §4 (wildcard consigliato vs solo `dev`).

### 2.3 Avviare rio

```bash
cd /home/tib/rio
docker compose -f docker-compose.dist.yml up -d
# verifica che il frontend ascolti sull'host:
curl -I http://localhost:5173
```

### 2.4 Ricreare/ricaricare l'nginx di konnex

```bash
cd /home/tib/konnex
docker compose -f .compose/dev.yml up -d nginx   # serve "up", non solo reload,
                                                 # se cambiano rete o extra_hosts
```

---

## 3. Opzioni per collegare l'nginx di konnex a rio

L'nginx di konnex deve poter **raggiungere** il frontend di rio. Sono in due reti docker
diverse (`konnex_nw` e `rioaction_nw`), quindi serve un ponte. Tre approcci.

### Opzione A — Rete docker condivisa (CONSIGLIATA)

Si crea una rete docker esterna a cui si agganciano sia l'nginx di konnex sia il frontend
di rio; l'instradamento avviene **per nome container**.

**Pro**
- Più robusta: non dipende dalla porta pubblicata sull'host.
- Permette di **non esporre più** la 5173 di rio su internet (puoi togliere il `ports:`).
- È l'approccio "docker-native", isola il traffico interno.

**Contro**
- Richiede di modificare **entrambi** i `docker-compose` e ricreare gli stack.

**Modifiche**

```bash
docker network create shared_edge
```

`rio/docker-compose.dist.yml` — servizio `frontend`:
```yaml
  frontend:
    # ...
    networks:
      - project_nw
      - shared_edge          # <─ aggiunto
# in fondo, sezione networks:
networks:
  project_nw:
    name: rioaction_nw
    # ...
  shared_edge:               # <─ aggiunto
    external: true
```

`konnex/.compose/dev.yml` — servizio `nginx`:
```yaml
  nginx:
    # ...
    networks:
      - konnex_nw
      - shared_edge          # <─ aggiunto
networks:
  konnex_nw:
    driver: bridge
    attachable: true
  shared_edge:               # <─ aggiunto
    external: true
```

`konnex/api/docker/dev/nginx/nginx.conf` — upstream:
```nginx
  upstream rio {
    server rioaction_frontend:5173;
  }
```

---

### Opzione B — `host-gateway` (RAPIDA)

Si sfrutta la porta 5173 che rio **pubblica già** sull'host, raggiungendola da dentro il
container nginx tramite `host.docker.internal`.

**Pro**
- Si tocca **solo** lo stack di konnex (nginx.conf + un'aggiunta al compose).
- rio resta invariato.

**Contro**
- Meno pulita: dipende dalla porta host e dal fatto che rio la pubblichi.
- La 5173 resta esposta su internet (a meno di firewall) oltre che dietro il proxy.

**Modifiche**

`konnex/.compose/dev.yml` — servizio `nginx`, aggiungere:
```yaml
  nginx:
    # ...
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

`konnex/api/docker/dev/nginx/nginx.conf` — upstream:
```nginx
  upstream rio {
    server host.docker.internal:5173;
  }
```

---

### Opzione C — Stack separato `rio` come front (NON applicabile qui)

In teoria rio potrebbe avere il proprio nginx sulla 443 con il suo certificato.
**Non è praticabile** perché la 443 è già occupata da konnex. Resta valida solo se in
futuro si sposta konnex dietro un proxy unico o si separano i server/IP.
Menzionata per completezza.

---

## 4. Varianti per il certificato

Si usa l'immagine `certbot-dns-hetzner` già presente in `konnex/.certbot`
(challenge DNS-01 via token Hetzner in `~/.config/certbot/certbot.env`).

### 4.1 Wildcard `*.tibadmin.xyz` (CONSIGLIATO)

Copre `dev`, `flower`, e qualsiasi futuro sottodominio in un colpo solo.

```bash
cd /home/tib/konnex/.certbot
make build
docker run --rm \
  --env-file ~/.config/certbot/certbot.env \
  -v /etc/letsencrypt:/etc/letsencrypt \
  -v /var/lib/letsencrypt:/var/lib/letsencrypt \
  certbot-dns-hetzner certonly \
    --dns-hetzner --dns-hetzner-credentials /tmp/hetzner.ini \
    --dns-hetzner-propagation-seconds 60 \
    --cert-name tibadmin.xyz \
    -d tibadmin.xyz -d '*.tibadmin.xyz' \
    --agree-tos -m api.tibadmin@gmail.com
```

### 4.2 Solo `dev.tibadmin.xyz` (minimale)

```bash
# ... stesso preambolo docker run ...
    --cert-name tibadmin.xyz \
    -d tibadmin.xyz -d dev.tibadmin.xyz \
    --agree-tos -m api.tibadmin@gmail.com
```

> `--cert-name tibadmin.xyz` mantiene lo stesso percorso `live/tibadmin.xyz/`
> già referenziato dall'nginx: **non servono modifiche ai path** nel config.
> Dopo il rilascio, ricaricare nginx (vedi §2.4).

---

## 5. Server block nginx per `dev.tibadmin.xyz`

Da aggiungere a `konnex/api/docker/dev/nginx/nginx.conf` (l'upstream `rio` è definito
secondo l'opzione A o B scelta al §3). Il blocco `http { ... }` ha già un
`ssl_certificate` globale che punta a `live/tibadmin.xyz/`, quindi dopo aver esteso il
cert (§4) questo server block lo eredita automaticamente.

```nginx
  # redirect 80 -> 443 per dev
  server {
    listen 80;
    server_name dev.tibadmin.xyz;
    return 301 https://$host$request_uri;
  }

  # dev.tibadmin.xyz -> rio
  server {
    listen 443 ssl http2;
    server_name dev.tibadmin.xyz;

    client_max_body_size 100M;

    location / {
      proxy_pass http://rio;
      proxy_set_header Host              $host;
      proxy_set_header X-Real-IP         $remote_addr;
      proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;

      proxy_http_version 1.1;
      proxy_set_header Upgrade    $http_upgrade;   # WebSocket (/ws/)
      proxy_set_header Connection $connection_upgrade;

      proxy_read_timeout 86400;
      proxy_send_timeout 86400;
      proxy_buffering    off;
    }
  }
```

> Nota: rio ha `ALLOWED_HOSTS=*` e `CORS_ALLOW_ALL_ORIGINS=True`, e il suo nginx interno
> già inoltra `/api/`, `/media/`, `/admin/`, `/static/`, `/ws/` al backend. Il frontend usa
> path relativi, quindi funziona dietro qualunque host senza rebuild.

---

## 6. Checklist finale

- [ ] DNS: record `A` (e `AAAA`) per `dev` → IP del server.
- [ ] Certificato esteso a `dev.tibadmin.xyz` (wildcard consigliato).
- [ ] Scelta opzione collegamento (A consigliata / B rapida) e relative modifiche.
- [ ] Server block `dev.tibadmin.xyz` aggiunto in `nginx.conf`.
- [ ] rio avviato (`docker compose -f docker-compose.dist.yml up -d`).
- [ ] nginx di konnex ricreato (`docker compose -f .compose/dev.yml up -d nginx`).
- [ ] Verifica: `curl -I https://dev.tibadmin.xyz` → 200 dal frontend di rio.

---

## 7. Raccomandazione sintetica

- **Collegamento:** Opzione A (rete condivisa) — più solida e ti permette di togliere la
  5173 da internet.
- **Certificato:** wildcard `*.tibadmin.xyz` — risolve anche `flower` e i sottodomini futuri.
- **Cosa posso fare io:** le edit ai file (`nginx.conf` + compose).
  **Cosa resta a te:** record DNS su Hetzner e lancio di certbot (richiede il token).
```
