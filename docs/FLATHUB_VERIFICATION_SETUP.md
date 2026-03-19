# Come far funzionare l’URL di verifica Flathub

L’URL `https://marcodigiangiacomo.github.io/.well-known/org.flathub.VerifiedApps.txt` funziona solo se esiste un **sito GitHub Pages** per l’account **marcodigiangiacomo** e il file è stato creato lì.

---

## Opzione A: Hai accesso all’account GitHub “marcodigiangiacomo”

Segui questi passi.

### 1. Crea il repository per GitHub Pages

1. Accedi a GitHub con l’account **marcodigiangiacomo**.
2. **New repository**.
3. **Repository name:** esattamente **`marcodigiangiacomo.github.io`** (nessuno spazio, tutto minuscolo).
4. Pubblica il repo (Public, senza README va bene).

### 2. Aggiungi il file di verifica

1. Nel repo **marcodigiangiacomo.github.io**, clicca **Add file** → **Create new file**.
2. Nel campo del **nome file** scrivi:
   ```text
   .well-known/org.flathub.VerifiedApps.txt
   ```
   (GitHub creerà da solo la cartella `.well-known`).
3. Nel **contenuto** del file metti il token che Flathub ti ha mostrato, su una sola riga. Esempio (sostituisci con il token reale che vedi su Flathub):
   ```text
   # io.github.marcodigiangiacomo.SuperLinuxUtility
   4bf0fdcb-018b-4895-blac-494e39e0350b
   ```
   Oppure solo:
   ```text
   4bf0fdcb-018b-4895-blac-494e39e0350b
   ```
4. **Commit** (es. “Add Flathub verification”).

### 3. Abilita GitHub Pages

1. Nel repo: **Settings** → **Pages** (menu sinistro).
2. **Source:** “Deploy from a branch”.
3. **Branch:** `main` (o `master`), cartella **/ (root)**.
4. **Save**.

Attendi 1–2 minuti, poi apri:

**https://marcodigiangiacomo.github.io/.well-known/org.flathub.VerifiedApps.txt**

Dovresti vedere il token. A quel punto su Flathub puoi cliccare **Continue**.

---

## Opzione B: Non hai accesso a “marcodigiangiacomo”

Se il tuo account è **sviluppoarte1-lang** e non puoi usare **marcodigiangiacomo**, l’unica strada è usare un App ID legato al tuo account, così la verifica sarà su **sviluppoarte1-lang.github.io**.

1. Su Flathub **torna indietro** (o ricomincia “New Direct Upload App”).
2. Come **App ID** inserisci:
   ```text
   io.github.sviluppoarte1-lang.SuperLinuxUtility
   ```
3. Clicca **Verify App ID**.
4. Flathub ti chiederà di creare il file su:
   **https://sviluppoarte1-lang.github.io/.well-known/org.flathub.VerifiedApps.txt**
5. Crea il repo **sviluppoarte1-lang.github.io** (sotto il tuo account), aggiungi il file `.well-known/org.flathub.VerifiedApps.txt` con il nuovo token che Flathub ti mostrerà, abilita Pages come sopra.
6. Dopo dovrai adattare manifest e metainfo all’App ID `io.github.sviluppoarte1-lang.SuperLinuxUtility` (nomi file, id nei contenuti, ecc.).

Se scegli l’opzione B, si possono aggiornare tutti i file del progetto (yml, metainfo, desktop) per usare il nuovo App ID.
