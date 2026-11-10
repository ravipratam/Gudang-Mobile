# Gudang Mobile - Warehouse Management System (WMS)

Aplikasi manajemen inventaris gudang berbasis mobile yang dirancang untuk mempermudah pencatatan, pemantauan, dan pergerakan stok barang secara real-time, akurat, dan efisien.

---

## 1. Penjelasan tentang Aplikasi

**Gudang Mobile** adalah aplikasi sistem manajemen gudang (*Warehouse Management System* - WMS) berbasis perangkat bergerak (*mobile*) yang dibangun dengan **Flutter** dan **Supabase**. Aplikasi ini berfungsi sebagai solusi terpadu untuk mendigitalkan seluruh aktivitas operasional pergudangan, mulai dari pencatatan barang masuk (*inbound*), pengeluaran barang (*outbound*), monitoring stok secara berkala, hingga pencetakan label QR Code produk.

Dengan arsitektur berbasis **MVVM (Model-View-ViewModel)** dan manajemen state menggunakan **Provider**, Gudang Mobile menyediakan antarmuka yang responsif, intuitif, dan terintegrasi langsung dengan database awan (*cloud database*) untuk memastikan konsistensi data inventaris antarpetugas di lapangan.

---

## 2. Tujuan Aplikasi

Pengembangan aplikasi Gudang Mobile ditujukan untuk:

1. **Digitalisasi & Efisiensi Operasional**: Menggantikan pencatatan inventaris manual berbasis kertas atau spreadsheet statis dengan sistem mobile yang cepat dan terintegrasi.
2. **Meminimalkan Kesalahan Manusia (*Human Error*)**: Mengurangi risiko salah hitung, salah ambil barang, atau duplikasi SKU (*Stock Keeping Unit*) dengan memanfaatkan pemindaian QR Code dan validasi data otomatis.
3. **Visibilitas Stok Real-Time**: Memberikan transparansi status ketersediaan barang secara akurat (stok aman, menipis, atau habis) guna mencegah keterlambatan suplai atau kehabisan stok (*stockout*).
4. **Mempercepat Alur Kerja Masuk & Keluar Barang**: Mempersingkat waktu pemrosesan transaksi *inbound* dan *outbound* di lantai gudang melalui fitur pemindaian cepat (*quick scan*).
5. **Akuntabilitas & Keamanan Data**: Memastikan setiap aktivitas perpindahan stok tercatat lengkap (waktu, jenis mutasi, kuantitas, catatan, dan nama petugas) dengan pembatasan hak akses berbasis peran (*Role-Based Access Control*).

---

## 3. Target Pengguna

Aplikasi ini dirancang untuk dua tingkatan pengguna utama di lingkungan pergudangan:

| Peran (*Role*) | Deskripsi Tanggung Jawab | Hak Akses Utama |
|---|---|---|
| **Administrator Gudang / Warehouse Manager** | Mengawasi keseluruhan inventaris, mengelola data master barang, dan memantau rekaman transaksi. | - Akses penuh ke seluruh fitur aplikasi.<br>- Menambah barang baru ke katalog.<br>- Mengatur kategori, kode SKU, lokasi rak, dan batas minimum stok.<br>- Melihat metrik performa gudang & riwayat mutasi lengkap.<br>- Mencetak dan mengekspor label QR Code. |
| **Staf Lapangan / Operator Gudang** | Melakukan aktivitas fisik pergudangan di lapangan seperti penerimaan, pengambilan (*picking*), dan pengecekan stok. | - Akses operasional harian.<br>- Memindai QR Code untuk mencari barang.<br>- Melakukan input mutasi barang masuk (*IN*) dan keluar (*OUT*).<br>- Melihat detail informasi produk dan lokasi rak penyimpanan.<br>- Memeriksa status ketersediaan barang.<br>- *Dibatasi:* Tidak dapat menambah produk baru ke master katalog. |

---

## 4. Fitur Utama

### A. Autentikasi & Role-Based Access Control (RBAC)
- **Sistem Keamanan Terintegrasi**: Pendaftaran akun baru (*Sign Up*), masuk (*Login*), dan setel ulang kata sandi (*Reset Password*).
- **Gerbang Otentikasi Reaktif (`AuthGate`)**: Memeriksa sesi pengguna secara otomatis saat aplikasi dibuka.
- **Pemisahan Peran Dinamis**: Tampilan tombol dan formulir peka terhadap peran aktif pengguna (Admin vs Staff).

### B. Dashboard Ringkasan & Sistem Peringatan Dini
- **Kartu Metrik Gudang**: Menampilkan total jenis produk, akumulasi unit stok fisik, dan jumlah barang yang menipis secara *live*.
- **Peringatan Stok Menipis (*Low Stock Alert*)**: Daftar peringatan visual khusus untuk produk yang stoknya berada di bawah ambang batas minimum atau kosong (*out of stock*).
- **Tombol Aksi Cepat (*Quick Action*)**: Tombol pintas untuk proses *Barang Masuk* dan *Barang Keluar* secara langsung dari halaman depan.

### C. Manajemen Master Produk & Katalog
- **Daftar & Pencarian Produk**: Pencarian instan berdasarkan nama atau SKU, dilengkapi filter kategori dan filter stok menipis.
- **Formulir Tambah Produk (Khusus Admin)**: Dilengkapi generator kode SKU otomatis (`Auto-SKU`) berawalan `PRD-` serta validasi pencegahan duplikasi kode SKU.
- **Halaman Detail Produk**: Menampilkan identitas barang, kategori, lokasi rak/zona penyimpanan, status ketersediaan, serta tautan ke pencetakan label dan riwayat transaksi barang tersebut.

### D. Pemindai & Pembangkit Label QR Code
- **Pemindai Barcode/QR Terintegrasi**: Menggunakan pustaka pemindai berkecepatan tinggi dengan dukungan multi-mode (*Search*, *Inbound*, *Outbound*).
- **Generator Label QR Code Standar WMS**: Menghasilkan label barang yang memuat kode QR, kode SKU, nama barang, kategori, dan lokasi rak.
- **Cetak & Ekspor PDF**: Dukungan pencetakan langsung ke printer nirkabel (Bluetooth/WiFi) atau ekspor dokumen label ukuran standar gudang (80mm x 55mm).

### E. Pencatatan Transaksi & Mutasi Stok (Inbound & Outbound)
- **Modal Aksi Stok Instan**: Menyesuaikan kuantitas barang masuk atau keluar disertai catatan referensi transaksi.
- **Validasi Kuantitas Transaksi**: Memastikan jumlah unit valid dan mencegah stok bernilai negatif akibat pengeluaran yang melebihi stok tersedia.

### F. Riwayat Transaksi & Audit Trail
- **Pencatatan Kronologis Lengkap**: Seluruh aktivitas mutasi stok tersimpan secara permanen mencakup tanggal/waktu, jenis transaksi, kuantitas, catatan, dan nama petugas pelaksana.
- **Filter Riwayat**: Memfilter daftar transaksi berdasarkan kategori *Semua*, *Barang Masuk (IN)*, atau *Barang Keluar (OUT)*.

---

## 5. Alur Pengguna (User Flow)

```
[Mulai]
   │
   ▼
[AuthGate] ──(Belum Login)──► [Halaman Login] ──► Masukkan Kredensial / Daftar Akun
   │                                                    │
   │ (Sudah Terautentikasi)                             ▼
   └───────────────────────────► [Dashboard Utama] ◄────┘
                                        │
         ┌──────────────────────────────┼──────────────────────────────┐
         ▼                              ▼                              ▼
  [Aksi Cepat / QR]             [Katalog Produk]               [Riwayat Transaksi]
         │                              │                              │
         ├─ Scan QR Masuk (IN)          ├─ Cari & Filter Produk        ├─ Filter (IN / OUT / All)
         ├─ Scan QR Keluar (OUT)        ├─ Lihat Detail & Lokasi Rak   └─ Tinjau Audit Log Mutasi
         └─ Scan QR Cari Barang         ├─ Cetak Label PDF (Semua)
                                        └─ Tambah Produk Baru (Khusus Admin)
```

1. **Alur Masuk & Registrasi Pengguna**:
   - Pengguna membuka aplikasi; `AuthGate` memverifikasi sesi login.
   - Jika belum memiliki sesi aktif, pengguna diarahkan ke formulir Login (atau Register untuk pendaftaran akun).
   - Setelah kredensial terverifikasi, pengguna masuk ke `DashboardView` dengan profil dan peran yang sesuai.

2. **Alur Penambahan Produk Baru (Admin)**:
   - Admin menekan tombol *"Tambah Barang"* di Dashboard atau AppBar katalog.
   - Admin mengisi detail produk (SKU, nama produk, kategori, lokasi rak, stok awal, dan batas minimum stok). Admin dapat menekan tombol *"Auto"* untuk membuat SKU acak unik.
   - Sistem memvalidasi kelengkapan data dan keunikan SKU di database.
   - Setelah berhasil, produk langsung muncul pada katalog barang.

3. **Alur Mutasi Stok via Pemindai QR (Inbound & Outbound)**:
   - Petugas menekan pintasan *"Barang Masuk"* / *"Barang Keluar"* atau ikon *"Scan QR"*.
   - Arahkan kamera ponsel ke QR Code fisik barang.
   - Sistem mendeteksi kode SKU dan memunculkan pop-up modal aksi stok.
   - Petugas memasukkan kuantitas dan catatan transaksi, lalu menekan *"Simpan"*.
   - Stok barang terbarui seketika dan transaksi otomatis tercatat di log riwayat.

4. **Alur Pencetakan Label QR Code**:
   - Pengguna membuka halaman Detail Produk.
   - Menekan tombol *"Pratinjau Label"* atau *"Cetak Label QR"*.
   - Sistem menghasilkan dokumen PDF label gudang berukuran 80mm x 55mm yang siap dipratinjau, dibagikan, atau dicetak langsung via printer printer thermal/label.

---

## 6. Batasan Pengujian (Testing Scope & Limitations)

Pengujian perangkat lunak pada proyek ini diimplementasikan menggunakan kerangka kerja bawaan Flutter (`flutter_test`) untuk menjaga stabilitas dan integritas fungsional kode.

### A. Cakupan Pengujian yang Diterapkan (*In-Scope*)
- **Unit Testing**:
  - Logika perhitungan dan evaluasi ambang batas stok (`isLowStock`, `isOutOfStock`).
  - Serialisasi dan deserialisasi data model JSON (`ProductModel`, `StockTransactionModel`, `ProfileModel`).
  - Penanganan error khusus repositori, seperti deteksi pelanggaran batas unik SKU (*duplicate key constraint* kode `23505`).
  - Pengujian logika otentikasi pada *ViewModel* dan *Repository* (kredensial benar, akun tidak terdaftar, kata sandi keliru).
- **Widget & Flow Testing**:
  - Pengujian rute gerbang masuk `AuthGate` (keadaan belum login vs terotentikasi).
  - Tampilan formulir login dan pendaftaran akun tanpa elemen demo hardcoded.
  - Verifikasi pembatasan hak akses berbasis peran (**RBAC**):
    - Admin melihat tombol dan memiliki akses ke formulir *"Tambah Barang"*.
    - Staff tidak melihat tombol *"Tambah Barang"* dan diblokir dengan layar pemberitahuan jika mencoba mengakses formulir tambah produk.
  - Verifikasi notifikasi kesalahan interaktif (*SnackBar* / alert error) saat input tidak valid atau terjadi konflik SKU.

### B. Batasan Pengujian (*Testing Limitations*)
- **Simulasi Dependensi Backend (*Mocking*)**:
  - Seluruh pengujian otomatis dijalankan menggunakan repositori tiruan (*mock repository*) dan in-memory state. Pengujian tidak melakukan *live request* ke server Supabase produksi untuk menjamin kecepatan dan determinisme hasil tes.
- **Sensor Perangkat Keras Pemindai Kamera**:
  - Komponen pemindai fisik (`mobile_scanner`) tidak menerima input optik kamera nyata dalam lingkungan test otomatis (headless runner); pengujian alur pemindaian dilakukan melalui injeksi nilai string SKU langsung ke *ViewModel* dan controller terkait.
- **Pencetakan Fisik (*Physical Hardware Printing*)**:
  - Generator PDF diuji sebatas validitas kompilasi format dokumen dan *byte stream*; pengujian tidak mencakup pencetakan fisik langsung ke perangkat keras printer label/thermal.
- **Cakupan End-to-End (E2E) Antarperangkat**:
  - Belum dilakukan pengujian integrasi penuh lintas versi sistem operasi (*multi-version OS testing* pada Android/iOS) dan berbagai variasi rasio layar fisik perangkat secara terotomatisasi.
- **Pengujian Beban & Skalabilitas (*Load & Stress Testing*)**:
  - Pengujian saat ini berfokus pada kebenaran fungsional dan perilaku antarmuka pengguna; pengujian konkurensi skala besar dengan ribuan transaksi paralel belum dicakup dalam test suite otomatis.

---

## 7. Persyaratan Sistem & Dependensi Utama

- **Framework**: Flutter SDK (Dart SDK ^3.13.5)
- **State Management**: `provider: ^6.1.5+1`
- **Backend & Database**: `supabase_flutter: ^2.18.0`
- **QR & Scanner**: `mobile_scanner: ^7.4.2`, `qr_flutter: ^4.1.0`
- **Pelabelan & PDF**: `pdf: ^3.13.1`, `printing: ^5.15.1`
- **Styling & Utilitas**: `google_fonts: ^9.0.0`, `intl: ^0.20.3`, `shared_preferences: ^2.5.5`
