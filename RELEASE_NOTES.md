# MacBar Monitor - Release v2.0.3

A lightweight macOS menu bar system monitor that displays real-time system metrics directly in your menu bar.

---

## 🛠️ Bug Fixes & Perbaikan di v2.0.3

- 📐 **Fix Progress Bar Alignment**: Memperbaiki tampilan progress bar (CPU, Memory, Swap, Battery, Disk) agar rata dan sejajar secara konsisten menggunakan layout kolom fixed-width.
- 🔧 **Fix Row Alignment (Upload/Download)**: Menambahkan placeholder pada row tanpa progress bar agar kolom value tetap sejajar.
- 📏 **Fix "Zero bytes/s" di Menu Bar**: Mengganti `ByteCountFormatter` dengan custom formatter yang lebih ringkas — sekarang menampilkan `0 B/s` alih-alih `Zero bytes/s`.

---

## 🛠️ Bug Fixes & Perbaikan di v2.0.1

- 🌐 **Fix Network Rate Spikes (GB/s Bug)**: Menambahkan sampling atomic pada counter interface jaringan sehingga perhitungan kalkulasi kecepatan upload & download akurat (KB/s / MB/s) dan tidak melompat ke GB/s.
- 💾 **Fix Memory Used & Total RAM**: Perhitungan total RAM sekarang akurat sesuai kapasitas fisik Mac (misal: 8 GB), dan memori terpakai menghitung Active + Wired + Compressed RAM seperti pada macOS Activity Monitor.
- 🔄 **Fix Swap Memory**: Membaca struct data kernel `vm.swapusage` dengan benar melalui POSIX `sysctlbyname`, menampilkan penggunaan memori swap (digunakan / total GB) secara presisi.
- 🌡️ **Fix Redundant Thermal Badge**: Memperbaiki tampilan Thermal agar tidak ada duplikasi teks di sebelah badge status suhu.
- 🎓 **Fix Show Tutorial di Settings**: Mengklik tombol "Show Tutorial" di Settings sekarang otomatis menutup popover dan menampilkan window tutorial onboarding.

---

## 🚀 Fitur Utama (v2 Series)

- 📊 **CPU Usage**: Pemantauan persentase utilisasi CPU secara real-time dengan mini progress bar.
- 💾 **Memory (RAM) Usage**: Informasi penggunaan memori RAM (Used / Total GB) & progress bar.
- 🔄 **Swap Usage**: Pemantauan penggunaan swap memory (GB).
- 🌡️ **Thermal State**: Indikator status suhu sistem (Normal, Elevated, Hot, Critical) dengan status badge berwarna.
- 🔋 **Battery Status**: Persentase daya baterai dan indikator pengisian daya (MacBook).
- 🌐 **Network Activity**: Kecepatan Upload (↑) dan Download (↓) dalam real-time.
- 💽 **Disk Capacity**: Kapasitas ruang penyimpanan disk tersisa (GB) & progress bar.
- ⚙️ **Multi-Metric Menu Bar**: Memilih lebih dari satu metrik untuk ditampilkan langsung di menu bar sekaligus.
- 🚀 **Launch at Login**: Opsi auto-start saat Mac di-restart melalui `SMAppService` bawaan macOS.
- ⏱️ **Refresh Rate Configurable**: Pilihan interval pembaruan data (1s, 2s, 5s, 10s).
- 🎓 **Onboarding Wizard**: Panduan awal 4 halaman untuk pengguna baru.
- 🔒 **Privacy & Local Only**: Tanpa pengumpulan data, tanpa telemetry, dan tanpa koneksi ke server eksternal.

---

## 📦 Instalasi & Cara Update

- **OS**: macOS 14.0 (Sonoma) atau lebih baru

### Opsi 1: installer DMG (Rekomendasi)
1. Download file `MacBarMonitor-v2.0.3.dmg` (atau buat sendiri dengan `./create-dmg.sh`).
2. Buka DMG lalu drag `MacBarMonitor.app` ke folder `Applications`.
3. Jika sudah ada versi lama di `Applications`, pilih **Replace** (Timpa). Tidak perlu menghapus manual terlebih dahulu.

### Opsi 2: Build dari Source
```bash
git clone git@github.com:pinoezz/macbar-monitor.git
cd macbar-monitor
./create-dmg.sh
open MacBarMonitor-v2.0.3.dmg
```
