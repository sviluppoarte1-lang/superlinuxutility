# Creare sviluppoarte1-lang.github.io per la verifica Flathub (da zero)

Non serve avere già un sito: crei **solo** il repo e **un file**. Tempo: 2 minuti.

---

## Passo 1: Crea il repository

1. Vai su **https://github.com/new** (accedi con **sviluppoarte1-lang**).
2. **Repository name:** scrivi **esattamente** (tutto minuscolo):
   ```text
   sviluppoarte1-lang.github.io
   ```
3. Scegli **Public**.
4. **Non** spuntare "Add a README file" (repo vuoto va bene).
5. Clicca **Create repository**.

---

## Passo 2: Aggiungi il file di verifica Flathub

1. Su Flathub, quando inserisci l’App ID **io.github.sviluppoarte1-lang.SuperLinuxUtility** e clicchi "Verify App ID", Flathub ti mostra un **token** (es. `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
2. Nel repo **sviluppoarte1-lang.github.io** appena creato:
   - Clicca **"Add file"** → **"Create new file"**.
3. **Nome del file:** nella barra in alto dove c’è il percorso, clicca e scrivi:
   ```text
   .well-known/org.flathub.VerifiedApps.txt
   ```
   (GitHub creerà da solo la cartella `.well-known`).
4. **Contenuto del file:** incolla **solo il token** che Flathub ti ha dato (una riga, nient’altro). Esempio:
   ```text
   a1b2c3d4-e5f6-7890-abcd-ef1234567890
   ```
5. In basso: **Commit new file** (titolo va bene "Add Flathub verification").

---

## Passo 3: Attiva GitHub Pages

1. Sempre nel repo **sviluppoarte1-lang.github.io**, vai in **Settings** (scheda in alto).
2. Menu a sinistra: **Pages**.
3. In **"Build and deployment"**:
   - **Source:** scegli **"Deploy from a branch"**.
   - **Branch:** scegli **main** (o **master** se è quello che usi), cartella **/ (root)**.
   - Clicca **Save**.
4. Aspetta **1–2 minuti**.

---

## Passo 4: Controlla che funzioni

Apri nel browser:

**https://sviluppoarte1-lang.github.io/.well-known/org.flathub.VerifiedApps.txt**

Dovresti vedere il token (una riga di testo). Se sì, su Flathub puoi cliccare **Continue**.

---

## Riepilogo

| Cosa | Dove |
|------|------|
| Repo | `sviluppoarte1-lang.github.io` (nome esatto) |
| File | `.well-known/org.flathub.VerifiedApps.txt` |
| Contenuto | Solo il token che Flathub ti dà |
| Pages | Settings → Pages → Deploy from branch **main** |

Dopo questo, **non** ti serve mettere altro su github.io: basta quel file per la verifica Flathub.
