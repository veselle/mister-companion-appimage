# mister-companion-appimage

Unofficial AppImage builds of [MiSTer Companion](https://github.com/Anime0t4ku/mister-companion).

A scheduled GitHub Action ([.github/workflows/build.yml](.github/workflows/build.yml)) checks the
upstream repository for new releases every 24 hours. When a new release is found:

1. The official `MiSTer-Companion-Linux-ARM64.tar.gz` and `MiSTer-Companion-Linux-x86_64.tar.gz`
   binaries are downloaded.
2. Each binary is repackaged as an AppImage using [`scripts/make-appimage.sh`](scripts/make-appimage.sh).
3. A release matching the upstream release's tag/title/notes is created in this repository (with a
   note that it's an unofficial, automated build), with `MiSTer-Companion-Linux-ARM64.AppImage` and
   `MiSTer-Companion-Linux-x86_64.AppImage` attached.

If a release for the current upstream tag already exists here, the workflow does nothing.

This project is not affiliated with or endorsed by the MiSTer Companion project.
