# Guida: pubblicare Super Linux Utility su Flathub

Procedura completa per sottomettere l’app a Flathub. Segui i passi in ordine.

---

## 0. Cosa ti serve

- Account GitHub (ce l’hai già)
- Account Flathub (ce l’hai già)
- Release pubblicata su GitHub con il tarball del bundle Linux (già fatto: tag 1.8.6)
- **SHA256 del tarball** (lo calcoli al passo 1)

---

## 1. Inserire lo SHA256 nel manifest

Flathub richiede lo SHA256 del file tarball per sicurezza.

1. Scarica il tarball dalla tua release (o usalo se ce l’hai già sul PC):
   - [Release 1.8.6](https://github.com/sviluppoarte1-lang/superlinuxutility/releases/tag/1.8.6) → `super-linux-utility-1.8.6-linux-bundle.tar.gz`
2. Dal terminale (nella cartella dove si trova il file):
   ```bash
   sha256sum super-linux-utility-1.8.6-linux-bundle.tar.gz
   ```
3. Copia la lunga stringa esadecimale (es. `a1b2c3d4e5f6...`).
4. Apri `flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.yml` e sostituisci **`REPLACE_WITH_SHA256`** con quella stringa. Salva il file.

---

## 2. Publisher Agreement Flathub (accordo di pubblicazione)

Prima di aprire la pull request devi accettare l’accordo per i publisher.

1. Vai su: **[Flathub – Publisher Submission Agreement](https://flathub.org/apps/new/publisher-agreement)**  
   (oppure da [flathub.org](https://flathub.org) → accedi → “Submit an app” / “Add app” fino alla pagina dell’accordo.)
2. Accedi con il tuo account Flathub (GitHub).
3. Leggi il **Publisher Submission Agreement**.
4. Accetta i termini (checkbox / pulsante “I agree” o simile).
5. Completa il flusso fino a conferma.

Se non trovi il link: da [docs.flathub.org – Submission](https://docs.flathub.org/docs/for-app-authors/submission) c’è il riferimento all’accordo; spesso si arriva dalla pagina “Submit a new app” su flathub.org.

---

## 3. Build e test in locale (consigliato)

Così verifichi che il manifest funzioni prima di inviare la PR.

1. Aggiungi il remote Flathub (una volta):
   ```bash
   flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
   ```
2. Installa il builder:
   ```bash
   flatpak install -y flathub org.flatpak.Builder
   ```
3. Dalla **root del progetto** (dove c’è la cartella `flathub/`), build e installa:
   ```bash
   flatpak run --command=flatpak-builder org.flatpak.Builder --install --user build-dir flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.yml
   ```
   Se il comando usato da Flathub è `flathub-build`:
   ```bash
   flatpak run --command=flathub-build org.flatpak.Builder --install flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.yml
   ```
4. Prova l’app:
   ```bash
   flatpak run io.github.marcodigiangiacomo.SuperLinuxUtility
   ```
5. Linter (controllo del manifest):
   ```bash
   flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.yml
   ```
   E per il metainfo:
   ```bash
   flatpak run --command=flatpak-builder-lint org.flatpak.Builder appstream flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.metainfo.xml
   ```
   Correggi eventuali errori segnalati.

---

## 4. Fork e branch del repository Flathub

1. Vai su **[github.com/flathub/flathub](https://github.com/flathub/flathub)**.
2. Clicca **Fork** (in alto a destra).  
   **Importante:** quando crei il fork, **deseleziona** “Copy the master branch only” (così avrai anche il branch `new-pr`).
3. Clona il **tuo** fork usando il branch **new-pr**:
   ```bash
   git clone --branch=new-pr https://github.com/TUO_USERNAME_GITHUB/flathub.git
   cd flathub
   ```
   Sostituisci `TUO_USERNAME_GITHUB` con il tuo username (es. quello dell’account che ha fatto il fork).
4. Crea un branch per la submission:
   ```bash
   git checkout -b add-super-linux-utility new-pr
   ```

---

## 5. Aggiungere i file dell’app nel fork

La struttura su Flathub deve essere:

```
flathub/
  apps/
    io.github.marcodigiangiacomo.SuperLinuxUtility/
      io.github.marcodigiangiacomo.SuperLinuxUtility.yml
      io.github.marcodigiangiacomo.SuperLinuxUtility.metainfo.xml
      super-linux-utility.desktop
      assets/
        icons/
          icon.png
```

1. Dalla root del repo `flathub` che hai clonato:
   ```bash
   mkdir -p apps/io.github.marcodigiangiacomo.SuperLinuxUtility/assets/icons
   ```
2. Copia i file dalla cartella `flathub/` del **tuo progetto Super Linux Utility**:
   ```bash
   cp /PERCORSO/DEL/TUO/PROGETTO/flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.yml \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/
   cp /PERCORSO/DEL/TUO/PROGETTO/flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.metainfo.xml \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/
   cp /PERCORSO/DEL/TUO/PROGETTO/flathub/super-linux-utility.desktop \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/
   cp /PERCORSO/DEL/TUO/PROGETTO/flathub/assets/icons/icon.png \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/assets/icons/
   ```
   Oppure, se sei nella root del progetto Super Linux Utility:
   ```bash
   cd /path/to/flathub   # il repo flathub clonato
   cp /path/to/superlinuxutility/flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.yml \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/
   cp /path/to/superlinuxutility/flathub/io.github.marcodigiangiacomo.SuperLinuxUtility.metainfo.xml \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/
   cp /path/to/superlinuxutility/flathub/super-linux-utility.desktop \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/
   mkdir -p apps/io.github.marcodigiangiacomo.SuperLinuxUtility/assets/icons
   cp /path/to/superlinuxutility/flathub/assets/icons/icon.png \
      apps/io.github.marcodigiangiacomo.SuperLinuxUtility/assets/icons/
   ```
3. Controlla che non ci sia più `REPLACE_WITH_SHA256` nel `.yml` (deve esserci lo SHA256 vero).
4. Aggiungi e committa:
   ```bash
   git add apps/io.github.marcodigiangiacomo.SuperLinuxUtility/
   git status   # verifica che ci siano i 4 file
   git commit -m "Add io.github.marcodigiangiacomo.SuperLinuxUtility"
   git push origin add-super-linux-utility
   ```

---

## 6. Aprire la Pull Request

1. Vai sul **tuo** fork su GitHub: `https://github.com/TUO_USERNAME_GITHUB/flathub`.
2. Dovrebbe comparire un banner “Compare & pull request” per il branch `add-super-linux-utility`. Cliccalo.  
   Altrimenti: **Pull requests** → **New pull request** → base: **flathub/flathub**, branch **new-pr**; compare: **tuo fork**, branch **add-super-linux-utility**.
3. **Base branch:** deve essere **`new-pr`** del repo **flathub/flathub** (non `master`).
4. **Titolo della PR:**  
   `Add io.github.marcodigiangiacomo.SuperLinuxUtility`
5. Nella descrizione puoi scrivere ad esempio:
   - Nome app: Super Linux Utility  
   - Link al codice: https://github.com/sviluppoarte1-lang/superlinuxutility  
   - Breve descrizione (es. “System management app for Linux: services, startup apps, cleanup, monitor, disk analyzer. Standard free, Advanced paid.”)
6. Clicca **Create pull request**.

---

## 7. Dopo l’invio della PR

- I reviewer Flathub commenteranno la PR. Rispondi e applica le modifiche richieste direttamente nel branch della PR (non serve chiudere e riaprire).
- Per avviare un **test build** in automatico, un reviewer o tu (se consentito) può commentare nella PR:
  ```text
  bot, build
  ```
- Quando la PR viene **approvata e mergiata**, Flathub creerà un repo dedicato all’app e ti inviterà con **write access**. Attiva la **2FA su GitHub** e **accetta l’invito entro una settimana**.
- Dopo il merge, la build ufficiale viene pubblicata di solito entro 1–2 ore; l’app comparirà sul sito Flathub in seguito.

---

## Riepilogo checklist

- [ ] SHA256 inserito in `io.github.marcodigiangiacomo.SuperLinuxUtility.yml` (niente più `REPLACE_WITH_SHA256`)
- [ ] Publisher Agreement Flathub accettato
- [ ] (Opzionale) Build locale e linter eseguiti senza errori
- [ ] Fork di flathub/flathub con “Copy the master branch only” **deselezionato**
- [ ] Branch `new-pr` usato come base, branch tipo `add-super-linux-utility` creato
- [ ] File dell’app copiati in `apps/io.github.marcodigiangiacomo.SuperLinuxUtility/`
- [ ] PR aperta contro **new-pr** (non master), titolo “Add io.github.marcodigiangiacomo.SuperLinuxUtility”

---

## Link utili

- [Flathub – Submission (documentazione)](https://docs.flathub.org/docs/for-app-authors/submission)
- [Flathub – Publisher Agreement](https://flathub.org/apps/new/publisher-agreement)
- [Flathub – Requirements](https://docs.flathub.org/docs/for-app-authors/requirements)
- [Repository Flathub su GitHub](https://github.com/flathub/flathub)
- [Super Linux Utility – Release 1.8.6](https://github.com/sviluppoarte1-lang/superlinuxutility/releases/tag/1.8.6)
