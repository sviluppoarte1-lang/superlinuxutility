# Flathub: cosa fare passo passo (senza confusione)

Hai già il repo **sviluppoarte1-lang/superlinuxutility** con le release. Quello resta com’è.  
Per Flathub servono **due cose separate**:

1. **App ID + verifica** (con github.io)
2. **Manifest** (che punta alla tua release esistente)

---

## Differenza importante

| Cosa | A cosa serve |
|------|----------------|
| **github.com/sviluppoarte1-lang/superlinuxutility** | Il tuo progetto: codice, release, .deb. **Non tocchi nulla.** |
| **sviluppoarte1-lang.github.io** | Un **altro** repo, solo per far vedere a Flathub che sei tu. Contiene **un solo file** con un token. |

Quindi: **github.io non è il tuo progetto**, è solo la “prova di identità” che Flathub chiede.

---

## Parte 1: Su Flathub (App ID e verifica)

1. Vai su Flathub → **Publish** → **New Direct Upload App** (dopo aver accettato il publisher agreement).

2. Nel campo **App ID** scrivi **esattamente**:
   ```text
   io.github.sviluppoarte1-lang.SuperLinuxUtility
   ```

3. Clicca **Verify App ID**.

4. Flathub ti mostrerà un **token** (tipo `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`) e ti chiederà di creare questa pagina:
   ```text
   https://sviluppoarte1-lang.github.io/.well-known/org.flathub.VerifiedApps.txt
   ```
   con **dentro il file** solo quel token (una riga).

5. **Copia il token** (tienilo da parte).

---

## Parte 2: Creare sviluppoarte1-lang.github.io (solo per il token)

Questo è un **nuovo** repo, solo per la verifica. Non è il repo dell’app.

1. Vai su **https://github.com/new**
2. **Repository name:** scrivi **esattamente** (tutto minuscolo):
   ```text
   sviluppoarte1-lang.github.io
   ```
3. **Public** → **Create repository** (niente README, va bene vuoto).

4. Nel repo appena creato:
   - **Add file** → **Create new file**
   - Nome file: **`.well-known/org.flathub.VerifiedApps.txt`**
   - Contenuto: **incolla solo il token** che Flathub ti ha dato (una riga, nient’altro)
   - **Commit new file**

5. **Settings** → **Pages** (menu a sinistra):
   - Source: **Deploy from a branch**
   - Branch: **main** (o master), cartella **/ (root)**
   - **Save**

6. Aspetta 1–2 minuti, poi apri nel browser:
   ```text
   https://sviluppoarte1-lang.github.io/.well-known/org.flathub.VerifiedApps.txt
   ```
   Devi vedere solo il token (una riga). Se sì, la verifica è ok.

---

## Parte 3: Tornare su Flathub e continuare

1. Torna sulla pagina Flathub dove avevi inserito l’App ID.
2. Clicca **Continue** (ora che l’URL con il token funziona, la verifica va a buon fine).

3. Flathub ti chiederà come vuoi fornire l’app (es. **caricare il manifest** o **link al repo**):
   - Se chiede il **manifest**: usa il file  
     `flathub/io.github.sviluppoarte1-lang.SuperLinuxUtility.yml`  
     del tuo progetto (quello che punta già alla tua release 1.8.6).
   - Se chiede il **repo**: indica  
     **https://github.com/sviluppoarte1-lang/superlinuxutility**  
     e il percorso del manifest (es. `flathub/io.github.sviluppoarte1-lang.SuperLinuxUtility.yml`).

La **release** che usi è sempre quella che hai già:  
https://github.com/sviluppoarte1-lang/superlinuxutility/releases  
Non devi creare nuove release per Flathub.

---

## Riepilogo

| Dove | Cosa fai |
|------|----------|
| **Flathub** | App ID = `io.github.sviluppoarte1-lang.SuperLinuxUtility` → Verify → poi Continue e fornisci manifest/repo |
| **GitHub (nuovo repo)** | Crei **sviluppoarte1-lang.github.io** con il file `.well-known/org.flathub.VerifiedApps.txt` (solo il token) e attivi Pages |
| **GitHub (superlinuxutility)** | Non cambi nulla; le release restano lì e Flathub le userà |

github.io serve **solo** per quel file con il token. Il tuo progetto e le release stanno solo in **sviluppoarte1-lang/superlinuxutility**.
