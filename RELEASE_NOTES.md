# MacBar Monitor - Release v1.0.0

A lightweight macOS menu bar system monitor that displays real-time system metrics directly in your menu bar.

---

## 🚀 Fitur Utama (Features)

- 📊 **CPU Usage**: Pemantauan persentase utilisasi CPU secara real-time.
- 💾 **Memory (RAM) Usage**: Informasi penggunaan memori RAM (Used / Total).
- 🔄 **Swap Usage**: Pemantauan penggunaan swap memory.
- 🌡️ **Thermal State**: Indikator status suhu sistem (Normal, Elevated, Hot, Critical).
- 🔋 **Battery Status**: Persentase daya baterai dan indikator pengisian daya (MacBook).
- 🌐 **Network Activity**: Kecepatan Upload (↑) dan Download (↓) dalam real-time (KB/s / MB/s).
- 💽 **Disk Capacity**: Kapasitas ruang penyimpanan disk yang tersisa.
- ⚙️ **Kustomisasi Menu Bar**: Pilihan metrik utama yang ingin ditampilkan di menu bar.
- ⏱️ **Refresh Rate Configurable**: Pilihan interval pembaruan data (1s, 2s, 5s, 10s).
- 🎓 **Onboarding Wizard**: Panduan awal 4 halaman untuk pengguna baru.
- 🔒 **Privacy & Local Only**: Tanpa pengumpulan data, tanpa telemetry, dan tanpa koneksi ke server eksternal.

---

## 🐛 Known Issues (Bug yang Diketahui di v1)

- ⚠️ **Settings Tidak Bisa Dibuka**: Terjadi kendala di mana menu/halaman Settings tidak dapat dibuka di versi v1 ini.
- ⚠️ **Auto-Run After Restart**: Aplikasi belum otomatis berjalan kembali secara otomatis setelah Mac di-restart/reboot.

---

## 📦 Persyaratan Sistem & Instalasi

- **OS**: macOS 14.0 (Sonoma) atau lebih baru
- **Build dari Source**:
  ```bash
  git clone git@github.com:pinoezz/macbar-monitor.git
  cd macbar-monitor
  ./bundle.sh
  open MacBarMonitor.app
  ```
