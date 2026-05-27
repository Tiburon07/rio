# RIO — Guida all'installazione

## Cos'è Rio?

Rio è il tuo quartier generale personale per gestire progetti e attività di sviluppo software, con un assistente AI integrato che lavora al tuo fianco.

### Cosa puoi fare

**Organizza il tuo lavoro**
Crei progetti e dentro ogni progetto gestisci le attività (task) su una board kanban — trascinale da "Da fare" a "In corso" a "Completato". Aggiungi note alle attività con il tempo impiegato, allegati, screenshot. Usa tag e priorità per trovare subito quello che conta.

**Fai lavorare l'AI per te**
Con un click, per ogni attività puoi chiedere all'AI di analizzare il problema, implementare il codice, scrivere i test o generare documentazione tecnica e per utenti finali. Puoi scegliere quale AI usare: Claude, Cursor o Codex. Mentre l'AI lavora, vedi il progresso in tempo reale.

**Lavora direttamente sul codice**
Senza uscire dalla piattaforma puoi sfogliare i file del tuo progetto, aprire un terminale direttamente nella cartella del progetto e gestire i branch Git (crea, cambia, aggiorna).

**Collega GitLab**
Se usi GitLab, puoi vedere pipeline, branch, tag e avviare job manualmente — tutto dalla pagina del progetto.

**Workflow automatizzati**
Definisci sequenze di passi ripetibili (analisi → implementazione → test → deploy) e applicale a qualsiasi attività con un click, con possibilità di approvare ogni passaggio prima di procedere.

**Documentazione sempre aggiornata**
Ogni progetto ha una sezione docs dove l'AI genera e mantiene aggiornata la documentazione tecnica e quella per gli utenti, organizzata ad albero.

> Un unico posto dove tenere i tuoi progetti, delegare il lavoro ripetitivo all'AI, scrivere codice, gestire Git e tenere traccia di tutto — senza cambiare tab.

---

## Installazione

RIO è un'applicazione web basata su Docker. Non è necessario installare Python, Node.js o altri linguaggi di programmazione: tutto gira all'interno di container Docker.

---

## Requisiti di sistema

| Software | Versione minima | Note |
|---|---|---|
| **Sistema operativo** | Linux (Ubuntu/Debian consigliato), macOS o Windows 10/11 | Su Windows usare WSL2 o Docker Desktop |
| **Docker** | 24.x o superiore | Motore per i container |
| **Docker Compose** | 2.x o superiore | Già incluso in Docker Desktop; su Linux installare separatamente |
| **Git** | qualsiasi versione recente | Per scaricare il codice |

---

## 1. Installare Docker

### Linux (Ubuntu/Debian)

Apri un terminale e incolla questi comandi uno alla volta:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Aggiungi il tuo utente al gruppo `docker` (evita di dover scrivere `sudo` ogni volta):

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Verifica che l'installazione sia andata a buon fine:

```bash
docker --version
docker compose version
```

### macOS / Windows

Scarica e installa **Docker Desktop** dal sito ufficiale:
👉 https://www.docker.com/products/docker-desktop/

Docker Desktop include automaticamente Docker Compose. Dopo l'installazione avvia l'applicazione e attendi che il motore sia pronto (icona balena nella barra di sistema).

---


## 2. Scaricare il progetto

Apri un terminale nella cartella dove vuoi installare l'applicazione, poi esegui:

```bash
git clone https://github.com/Tiburon07/rio.git
cd rio
```

---

## 3. Configurare il file `.env`

Copia il file di esempio e rinominalo:

```bash
cp .env.example .env
```

Apri il file `.env` con un editor di testo (puoi usare `nano`, `gedit`, Blocco Note su Windows, ecc.) e personalizza i valori seguenti:

### Valori obbligatori da modificare

```ini
# Cartella del tuo computer che l'app potrà esplorare (file browser)
# Imposta il percorso della cartella dove tieni i tuoi progetti/file
HOST_VOLUME=/home/TUONOME/progetti
BASE_CODE_PATH=/home/TUONOME/progetti

# Il tuo nome utente del sistema operativo
HOST_USER=TUONOME
HOST_HOME=/home/TUONOME

# Stesso nome utente, come appare nel container
CONTAINER_USER=TUONOME
# ID numerico del tuo utente (su Linux esegui: id -u)
CONTAINER_UID=1000

# Chiave segreta Django — cambia questa stringa con qualcosa di casuale
SECRET_KEY=metti-qui-una-stringa-casuale-lunga

# Percorso ASSOLUTO della cartella dove hai clonato questo repo
COMPOSE_PROJECT_PATH=/percorso/completo/dove/hai/clonato/rio
```

> **Nota:** su Linux puoi scoprire il tuo UID con il comando `id -u` e il percorso assoluto corrente con `pwd`.

### Strumenti AI (opzionali)

Se vuoi usare strumenti AI integrati (Claude, Gemini, Cursor, Codex, ecc.) inserisci i relativi percorsi binari e API key nelle variabili corrispondenti. Se non li usi puoi lasciare i valori di esempio o cancellare quelle righe.

```ini
CURSOR_API_KEY=la-tua-chiave-cursor
GEMINI_API_KEY=la-tua-chiave-gemini
```

### Database

Di default l'app usa **PostgreSQL**. È possibile passare a MySQL impostando `DB_ENGINE=mysql`.

**PostgreSQL (default):**

```ini
DB_ENGINE=postgresql
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=riouser
POSTGRES_PASSWORD=una-password-sicura
POSTGRES_DB=rioaction
```

**MySQL (alternativo):**

```ini
DB_ENGINE=mysql
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=riouser
MYSQL_PASSWORD=una-password-sicura
MYSQL_DATABASE=rioaction
```

**SQLite*

```ini
DB_ENGINE=sqlite
```

---

## 4. Avviare l'applicazione

Dalla cartella del progetto esegui:

```bash
docker compose -f docker-compose.dist.yml up -d
```

Docker scaricherà automaticamente tutte le immagini necessarie (operazione che richiede qualche minuto alla prima esecuzione) e avvierà tutti i servizi.

Per verificare che tutti i container siano in esecuzione:

```bash
docker compose -f docker-compose.dist.yml ps
```

Dovresti vedere questi servizi con stato `running`:

| Servizio | Descrizione |
|---|---|
| `rioaction_backend` | API Django (backend) |
| `rioaction_frontend` | Interfaccia web (frontend) |
| `rioaction_redis` | Cache e broker messaggi |
| `rioaction_celeryworker` | Esecutore task in background |
| `rioaction_flower` | Monitoraggio task Celery |
| `rioaction_codeserver` | Editor di codice integrato (VS Code web) |
| `rioaction_codeserver_proxy` | Proxy nginx per il code server |

---

## 5. Accedere all'applicazione

Una volta avviata, apri il browser e vai su:

| Servizio | URL | Descrizione |
|---|---|---|
| **Applicazione principale** | http://localhost:5173 | Interfaccia utente principale |
| **Monitoraggio task** | http://localhost:5555 | Flower — dashboard Celery |

---

## 6. Fermare l'applicazione

Per fermare tutti i container:

```bash
docker compose -f docker-compose.dist.yml down
```

Per fermarli e rimuovere anche i dati persistenti (attenzione: operazione irreversibile):

```bash
docker compose -f docker-compose.dist.yml down -v
```

---

## 7. Aggiornare l'applicazione

Quando è disponibile una nuova versione, apparirà un avviso direttamente nell'interfaccia della piattaforma. Clicca sul pulsante **Aggiorna** nell'alert per avviare l'aggiornamento automatico.


---

## 8. Visualizzare i log

Per vedere i log di tutti i servizi in tempo reale:

```bash
docker compose -f docker-compose.dist.yml logs -f
```

Per vedere i log di un singolo servizio (es. backend):

```bash
docker compose -f docker-compose.dist.yml logs -f backend
```

---

## Risoluzione problemi comuni

**Il comando `docker` non funziona senza `sudo` (Linux)**
→ Esegui `sudo usermod -aG docker $USER` poi chiudi e riapri il terminale.

**I container non si avviano / errori al primo avvio**
→ Controlla che le variabili `HOST_VOLUME` e `COMPOSE_PROJECT_PATH` nel file `.env` contengano percorsi esistenti sul tuo sistema.

**Porta già in uso (errore "address already in use")**
→ Un'altra applicazione sta usando quella porta

**Come trovare il mio UID su Linux**
→ Apri un terminale ed esegui `id -u`. Il numero restituito va inserito in `CONTAINER_UID`.

**L'applicazione è lenta al primo avvio**
→ È normale: Docker deve scaricare le immagini (~1-2 GB). Dalla seconda esecuzione si avvia in pochi secondi.
