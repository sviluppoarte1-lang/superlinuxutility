This folder contains all files suitable for publishing Super Linux Utility on GitHub.

Contents:
- Full Flutter source (lib/, assets/, linux/, etc.)
- pubspec.yaml, analysis_options.yaml, l10n.yaml
- build_deb.sh, build_rpm.sh (packaging scripts)
- tools/ (e.g. license_key_generator.dart)
- io.github.marcodigiangiacomo.SuperLinuxUtility.metainfo.xml (AppStream/Flathub metadata)
- DESCRIPTION_300_CHARS.txt (300-character English description for store listings)
- README.md, and other docs

Excluded from this copy: build/, .dart_tool/, deb_package*/, linux/flutter/ephemeral/, IDE files.

To publish: upload this folder as your GitHub repository, or use it as the base for a new repo. For releases, build the .deb packages with ./build_deb.sh and attach the resulting .deb files to GitHub Releases.
