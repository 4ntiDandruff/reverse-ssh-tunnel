# Reverse SSH Tunnel

**Masuk ke mesin yang tidak bisa dimasuki.**

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

Dari laptop kamu:

```bash
ssh -p 2223 <user>@<server-perantara>
```

Kalau berhasil, kamu sudah di dalam mesin terkunci.

## Biar Tidak Mati

VM bisa restart sewaktu-waktu. Pakai `ensure-up.sh` buat mastiin sshd dan tunnel selalu hidup. Pasang sebagai cron `@reboot` atau jalanin berkala.

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

## Lisensi

Bebas pakai, bebas modif. Kalau membantu, kasih bintang ya.
