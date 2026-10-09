<div align="center">

# Reverse SSH Tunnel

**Masuk ke mesin yang tidak bisa dimasuki.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-brightgreen.svg?style=flat-square)](https://github.com/4ntiDandruff/reverse-ssh-tunnel)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20POSIX-blue.svg?style=flat-square)](#)

<p align="center">
  <a href="https://megapass.web.id"><img src="https://img.shields.io/badge/Website-megapass.web.id-000?style=flat-square&logo=firefoxbrowser&logoColor=white" alt="Website" /></a>
  <a href="https://megapass.web.id/teknisi/"><img src="https://img.shields.io/badge/Portofolio-megapass.web.id%2Fteknisi-0A66C2?style=flat-square&logo=googlechrome&logoColor=white" alt="Teknisi" /></a>
  <a href="https://github.com/4ntiDandruff"><img src="https://img.shields.io/badge/GitHub-4ntiDandruff-24292e?style=flat-square&logo=github&logoColor=white" alt="GitHub" /></a>
</p>

---

</div>

Punya VM atau server yang cuma bisa koneksi keluar? Tidak punya IP publik? Firewall nutup semua pintu masuk? Pakai trik ini: suruh mesinnya yang telepon keluar dulu, lalu kamu masuk lewat sambungan itu.

## Cara Kerja (Simpel)

```
[Mesin Terkunci] --telepon keluar--> [Server Perantara] <--kamu masuk-- [Laptop Kamu]
```

1. Mesin terkunci buka koneksi SSH **keluar** ke server perantara (ini boleh, kan cuma nelpon keluar)
2. Di dalam koneksi itu, dia titip pesan: "kalau ada yang datang ke port 2223, teruskan ke saya"
3. Kamu SSH ke server perantara port 2223
4. Sampai deh di mesin terkunci

Tidak ada pintu baru yang dibuka. Cuma numpang lewat pintu keluar yang memang boleh dibuka dari dalam.

## Kapan Kamu Butuh Ini

- VM cloud tanpa IP publik
- Server di balik NAT yang tidak bisa setting port forwarding
- Mesin client-only (kayak sandbox AI) yang tolak semua koneksi masuk
- Akses dashboard internal (port 3000, 8080) dari jarak jauh tanpa expose ke internet

## Yang Kamu Butuhkan

- **Mesin terkunci**: bisa SSH keluar (port 22)
- **Server perantara**: bisa terima SSH, bisa kamu jangkau
- **Key SSH**: sepasang key untuk autentikasi

## Setup, Langkah per Langkah

### 1. Siapkan SSH khusus di mesin terkunci

Kenapa khusus? Biar tidak ganggu sshd utama. Kita jalanin sshd kedua yang cuma dengerin localhost.

```bash
mkdir -p ~/reverse-tunnel
```

Copy `sshd_config.example` jadi `sshd_config`, ganti `<user>` dengan username kamu.

Masukkan public key dari server perantara ke `authorized_keys`:

```bash
# Di server perantara, ambil public key:
cat ~/.ssh/id_ed25519.pub

# Tempel ke ~/reverse-tunnel/authorized_keys di mesin terkunci
```

Jalankan:

```bash
sudo mkdir -p /run/sshd
/usr/sbin/sshd -f ~/reverse-tunnel/sshd_config
```

### 2. Siapkan script tunnel

Copy `reverse-tunnel.sh.example` jadi `reverse-tunnel.sh`, isi bagian konfigurasi:

```bash
REMOTE_USER="user-server-perantara"
REMOTE_HOST="ip-server-perantara"
```

Jalankan di background (auto-reconnect kalau putus):

```bash
chmod +x ~/reverse-tunnel/reverse-tunnel.sh
nohup ~/reverse-tunnel/reverse-tunnel.sh > ~/reverse-tunnel/tunnel.log 2>&1 &
```

### 3. Buka keran di server perantara

Server perantara harus izinkan port forward diakses dari luar. Tambah ke `/etc/ssh/sshd_config`:

```
GatewayPorts yes
```

Restart:

```bash
sudo systemctl restart sshd
```

### 4. Masuk!

Dari laptop kamu atau server perantara:

```bash
ssh -p 2223 <user>@<server-perantara>
```

Atau jika masuk dari localhost server perantara (rekomendasi: gunakan `127.0.0.1` daripada `localhost` agar tidak bentrok IPv6 `::1`):

```bash
ssh -p 2223 root@127.0.0.1
```

Kalau berhasil, kamu sudah di dalam mesin terkunci.

## Biar Tidak Mati

VM bisa restart sewaktu-waktu. Pakai `ensure-up.sh` buat mastiin sshd dan tunnel selalu hidup. Pasang sebagai cron `@reboot` atau jalanin berkala.

### Kalau VM-mu sering di-reset total (Ephemeral Root + Persistent Home)

Beberapa platform (kayak sandbox AI atau VM runtime container) tidak cuma reboot biasa tapi **reset total**:
- Root filesystem (`/`) adalah ephemeral overlay: semua paket di luar home directory lenyap saat reset.
- Home directory (`$HOME` atau mount storage khusus) adalah **persistent storage** yang tidak ke-wipe.

Solusinya: `recover-node-muse.sh.example`. Script pemulihan ini dirancang dengan standar fail-safe teknisi:

1. **Verifikasi Instalasi Paket Real**:
   - Mengecek keberadaan biner SSH nyata (`command -v sshd`), bukan sekadar output log status.
   - Punya fallback otomatis mengekstrak file `.deb` dari cache lokal `/var/cache/apt/archives/` jika `apt-get` terkunci atau repository gagal dihubungi.
2. **Sirkuit Unpack `dpkg --configure -a`**:
   - Memastikan paket terkonfigurasi sempurna sehingga user privilege separation `sshd` otomatis tercipta dan tidak memicu crash daemon.
3. **Penyimpanan Cache Biner Persist**:
   - Binary utilitas (seperti Yazi, btop) dipulihkan langsung dari cache persistent (`$HOME/.local/bin/`) sebelum mengunduh via jaringan.
4. **Restore Lingkungan Shell & SSHD**:
   - Mengembalikan `.bashrc`, locale UTF-8, konfigurasi Yazi, lalu menyalakan ulang daemon SSH port 2222 dan reverse SSH loop.

Pasang sebagai hook watchdog berkala (misal tiap 5 menit). Script bersifat idempoten: jika semua komponen sehat, script diam dan tidak membebani sistem.

> **Aturan Emas**: Simpan semua konfigurasi, kunci SSH, dan skrip penting di dalam home directory / persistent storage. Anggap semua folder di luar itu bersifat sekali pakai.

## Soal Keamanan

Jujur ya:

- **Aman**: koneksi terenkripsi SSH penuh, tetap butuh key yang valid
- **Risiko**: siapa pun yang pegang key dan bisa akses server:2223 bisa masuk ke mesin kamu
- **Tips**: kalau cuma kamu yang butuh akses, ganti `0.0.0.0:2223` jadi `127.0.0.1:2223` di script. Artinya port cuma bisa diakses dari server perantara itu sendiri, bukan dari luar

Ini fitur resmi SSH, bukan hack. Tapi kayak pisau: bisa buat masak, bisa juga buat yang lain. Pakai dengan bijak.

## Isi Repo

| File | Buat apa |
|------|----------|
| `sshd_config.example` | Config sshd khusus (contoh, tinggal sesuaikan) |
| `reverse-tunnel.sh.example` | Script tunnel + auto-reconnect (contoh, tinggal isi variabel) |
| `ensure-up.sh` | Script jaga-jaga biar tunnel tidak mati |
| `recover-node-muse.sh.example` | Recovery lengkap pasca-reset total (reinstall paket + fallback deb lokal + restore config) |
| `CHANGELOG.md` | Rekam jejak pembaruan dan peningkatan ketahanan sistem |
| `LICENSE` | Lisensi MIT |

---

<div align="center">

**Megapass Intra Solusindo • Sidoarjo, Indonesia**  
*Teknisi Bersertifikasi BNSP & Praktisi Otomasi Sistem*

</div>
