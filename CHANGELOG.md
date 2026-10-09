# Changelog
Semua perubahan penting pada proyek **Reverse SSH Tunnel** dicatat dalam dokumen ini.

Format pencatatan merujuk pada standar [Keep a Changelog](https://keepachangelog.com/id/1.1.0/).

## [Unreleased] - 2026-10-10

### Ditambahkan
- Penanganan fail-safe pada script recovery pasca VM reset total (`recover-node-muse.sh.example`):
  - Deteksi kegagalan `apt-get` saat lock file dipegang proses lain dengan verifikasi keberadaan binary `command -v sshd`.
  - Fallback ekstraksi arsip `.deb` lokal dari `/var/cache/apt/archives/` jika repository tidak terjangkau.
  - Sirkuit `dpkg --configure -a` otomatis untuk memastikan user privilege separation `sshd` dibuat tanpa memicu kegagalan start daemon.
  - Optimasi pemulihan binary `yazi` dari direktori persistent `$HOME/.local/bin/` sebelum melakukan pengunduhan jaringan via `wget`.
- Dokumentasi pemulihan arsitektur ephemeral overlay root (`/`) vs persistent home volume (`$HOME`).
- Panduan mitigasi binding `127.0.0.1` vs `localhost` untuk mencegah masalah resolusi IPv6 `::1` pada reverse forwarding.
- Header dan footer identitas bengkel resmi Megapass Intra Solusindo.

## [1.0.0] - 2026-10-05

### Ditambahkan
- Konfigurasi daemon `sshd` terisolasi di port lokal 2222 (`sshd_config.example`).
- Script pembuka reverse tunnel otomatis dengan loop reconnection (`reverse-tunnel.sh.example`).
- Watchdog ringan pemantau ketersediaan daemon dan tunnel (`ensure-up.sh`).
- Template skrip pemulihan awal pasca-reset total sistem (`recover-node-muse.sh.example`).
- Dokumentasi panduan setup terstruktur dengan analogi bahasa manusiawi di `README.md`.
- Lisensi publik open-source MIT.
