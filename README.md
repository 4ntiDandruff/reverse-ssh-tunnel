# Reverse SSH Tunnel

Akses mesin yang tidak bisa menerima koneksi masuk (client-only, di balik NAT/firewall ketat)
via reverse SSH tunnel ke mesin perantara.

## Konsep

```
[VM Client-Only] ----SSH keluar----> [Server Perantara] <----SSH masuk---- [Klien]
     :2222                    port 22            :2223                  port 2223
```

VM membuka koneksi SSH keluar ke server perantara, lalu meminta server membuka
port 2223 yang diteruskan balik ke VM. Klien konek ke server:2223 dan sampai ke VM.

## Kebutuhan

- VM client-only: bisa SSH keluar, tidak bisa terima koneksi masuk
- Server perantara: bisa terima SSH, reachable oleh klien
- Klien: bisa SSH ke server perantara

## Setup

### 1. Di VM (client-only)

Install openssh-server, lalu buat sshd khusus yang hanya listen di localhost:

```bash
mkdir -p ~/reverse-tunnel
```

Salin `sshd_config.example` ke `~/reverse-tunnel/sshd_config`, sesuaikan `AllowUsers`.

Isi `authorized_keys` dengan public key dari server perantara:

```bash
# di server perantara
cat ~/.ssh/id_ed25519.pub
# salin output ke ~/reverse-tunnel/authorized_keys di VM
```

Jalankan sshd khusus:

```bash
sudo mkdir -p /run/sshd
/usr/sbin/sshd -f ~/reverse-tunnel/sshd_config
```

### 2. Buat script tunnel

Salin `reverse-tunnel.sh.example` ke `~/reverse-tunnel/reverse-tunnel.sh`,
sesuaikan variabel `REMOTE_USER`, `REMOTE_HOST`, `REMOTE_PORT`.

Jalankan dengan loop auto-reconnect:

```bash
chmod +x ~/reverse-tunnel/reverse-tunnel.sh
nohup ~/reverse-tunnel/reverse-tunnel.sh > ~/reverse-tunnel/tunnel.log 2>&1 &
```

### 3. Di server perantara

Aktifkan GatewayPorts agar port forward bisa diakses dari luar:

```bash
# /etc/ssh/sshd_config
GatewayPorts yes
```

```bash
sudo systemctl restart sshd
```

### 4. Test

Dari klien:

```bash
ssh -p 2223 <user>@<server-perantara>
```

Jika berhasil, klien sudah masuk ke VM.

## Recovery

Jalankan `ensure-up.sh` untuk memastikan sshd dan tunnel tetap hidup.
Bisa dipasang sebagai cron `@reboot` atau hook berkala.

## Keamanan

- Tunnel terenkripsi SSH penuh
- Tetap butuh SSH key yang valid untuk masuk
- Siapa pun yang pegang key dan bisa akses server:2223 bisa masuk ke VM
- Untuk isolasi lebih ketat, ganti `0.0.0.0:2223` jadi `127.0.0.1:2223`
  (hanya bisa diakses dari server perantara itu sendiri)

## File

| File | Fungsi |
|------|--------|
| `sshd_config.example` | Konfigurasi sshd khusus di VM |
| `reverse-tunnel.sh.example` | Script pembuat tunnel dengan auto-reconnect |
| `ensure-up.sh` | Script recovery sshd + tunnel |
