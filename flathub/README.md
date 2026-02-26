# Flathub packaging for Super Linux Utility

This folder contains everything needed to publish Super Linux Utility on Flathub.

## Contents

- **io.github.marcodigiangiacomo.SuperLinuxUtility.metainfo.xml** – AppStream metadata (required by Flathub)
- **io.github.marcodigiangiacomo.SuperLinuxUtility.yml** – Flatpak build manifest
- **super-linux-utility.desktop** – Desktop entry (used during build)
- **assets/icons/icon.png** – Application icon

## How to publish on Flathub

### 1. Build the Linux bundle

From the project root:

```bash
flutter build linux --release
```

### 2. Create a tarball for the bundle

```bash
cd build/linux/x64/release
tar czvf super-linux-utility-1.8.6-linux-bundle.tar.gz bundle/
# Or from bundle's parent: tar czvf ... -C bundle .
```

Rename/upload so the archive contains at the root: `lib/`, `data/`, and the `super_linux_utility` binary (i.e. the contents of `bundle/`, not a `bundle` folder).

### 3. Upload to GitHub Releases

Create a release (e.g. v1.8.6) and attach `super-linux-utility-1.8.6-linux-bundle.tar.gz`. Copy the URL and compute SHA256:

```bash
sha256sum super-linux-utility-1.8.6-linux-bundle.tar.gz
```

### 4. Update the manifest

In `io.github.marcodigiangiacomo.SuperLinuxUtility.yml`:

- Set `url` under the archive source to your release tarball URL
- Set `sha256` to the computed checksum

### 5. Submit to Flathub

- Fork [flathub/flathub](https://github.com/flathub/flathub)
- Add your app: create `apps/io.github.marcodigiangiacomo.SuperLinuxUtility/` and put the YAML manifest there
- Flathub can also use the manifest from your app repo: see [Flathub docs](https://docs.flathub.org/docs/for-app-authors/requirements) for “Build from manifest in app repo”
- Open a PR; Flathub will build and validate

### 6. Validate the metainfo locally (optional)

```bash
flatpak run --command=flatpak-builder-lint org.flatpak.Builder appstream io.github.marcodigiangiacomo.SuperLinuxUtility.metainfo.xml
```

(Requires `org.flatpak.Builder` from Flathub.)

## Tarball layout

The archive must extract to a directory that contains:

- `super_linux_utility` (executable)
- `lib/` (shared libraries)
- `data/` (Flutter assets)

So create it from inside `bundle/`:

```bash
cd build/linux/x64/release/bundle
tar czvf ../../super-linux-utility-1.8.6-linux-bundle.tar.gz .
```

Then upload the file from `build/linux/x64/release/`.
