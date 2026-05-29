# Dokumentasi Arsitektur File BusGuide 📖

Aplikasi BusGuide dibangun menggunakan arsitektur **MVC (Model-View-Controller)** yang dimodifikasi menggunakan *Provider* untuk State Management. Berikut adalah penjelasan mendetail untuk **setiap file** yang ada di dalam folder `lib/`.

---

## 1. 🟢 Root (Titik Awal Aplikasi)
*   **`main.dart`**
    Ini adalah jantung atau titik masuk (*entry point*) dari aplikasi Flutter. Di sinilah aplikasi dimulai, Supabase diinisialisasi, Notifikasi disiapkan, dan semua `Controller` (*Provider*) didaftarkan ke sistem sebelum aplikasi me-render halaman pertama (biasanya `splash_screen.dart`).

---

## 2. 🧠 Controllers (`lib/controllers/`)
Berfungsi sebagai **Otak Aplikasi**. Controller mengambil data mentah dari `models`, mengolah logika (menghitung ETA, jarak, filter, dll), dan menyimpan *State* (status loading, error, list data) untuk ditampilkan ke UI (`views`).

*   **`auth_controller.dart`**: Mengatur proses login, pendaftaran akun (register), validasi sesi, dan proses *logout*.
*   **`detail_po_bus_controller.dart`**: Menangani logika untuk menampilkan katalog dan detail dari sebuah Perusahaan Otobus (PO).
*   **`detail_wisata_controller.dart`**: Mengolah data untuk layar Detail Tempat Wisata (seperti jam buka, tarif, dll).
*   **`halte_controller.dart`**: Memuat daftar semua halte, dan memiliki logika untuk mencari halte dari map atau *Nominatim API*.
*   **`home_controller.dart`**: Mengatur data ringkas yang tampil di beranda aplikasi (seperti cuaca, atau rangkuman data cepat).
*   **`navigasi_controller.dart`**: Sangat penting! Mengurus logika persiapan navigasi (memilih Halte Asal dan Halte Tujuan) dan menentukan rute apakah harus pakai *database rute resmi* atau *Navigasi Bebas (OSRM)*.
*   **`navigasi_aktif_controller.dart`**: Penggerak utama saat navigasi sedang berjalan. Bertugas membaca data GPS *Real-Time*, memanggil OSRM, menghitung jarak ke tujuan, menghitung sisa waktu (ETA) dinamis, dan membunyikan alarm.
*   **`perjalanan_controller.dart`**: *(Optional/Riwayat)* Mengatur dan menyimpan histori semua perjalanan yang pernah dilakukan user.
*   **`profil_controller.dart`**: Mengambil data profil user (nama, inisial) dan memfasilitasi pengubahan (*edit*) profil.
*   **`rekomendasi_controller.dart`**: Mengolah algoritma untuk menampilkan daftar rute wisata atau rekomendasi PO Bus di halaman Rekomendasi.
*   **`riwayat_controller.dart`**: Memuat data perjalanan lampau pengguna untuk ditampilkan di halaman riwayat.
*   **`rute_controller.dart`**: Mengambil dan menyiapkan daftar rute (contoh: trayek AL, ADL) dari database.
*   **`wisata_controller.dart`**: Mengurus pengambilan daftar lokasi wisata untuk direktori wisata.

*(Note: File `bus_controller.dart` sudah bisa dihapus karena tidak digunakan).*

---

## 3. 📦 Models & Services (`lib/models/`)
Folder ini tidak berisi UI sama sekali. Ini berisi dua jenis file:
1.  **Model/Blueprint (tanpa akhiran `_service`)**: Berfungsi melakukan decoding JSON dari database ke dalam bentuk Class dart.
2.  **Service (dengan akhiran `_service`)**: Berfungsi membuat _query_ / berbisik langsung ke server API (Supabase atau OSRM).

*   **`auth_service.dart`**: Terkoneksi langsung dengan fitur *Authentication* dari Supabase server.
*   **`halte.dart` & `halte_service.dart`**: Model Halte dan fungsi query untuk mengambil data tabel `halte` di database.
*   **`notifikasi.dart`**: Struktur data untuk riwayat notifikasi/alarm.
*   **`osrm_routes_service.dart`**: Kurir yang melakukan *HTTP Request* ke server Peta OSRM (Gratis) untuk mengambil *polyline* dan jarak tempuh.
*   **`perjalanan.dart` & `perjalanan_service.dart`**: Menangani struktur data dan Insert/Update ke tabel `perjalanan` dan `riwayat_perjalanan` di Supabase.
*   **`po_bus.dart` & `po_bus_service.dart`**: Menangani tabel `po_bus` (Katalog Perusahaan Bus).
*   **`rute.dart` & `rute_service.dart`**: Menangani tabel `rute`, `rute_halte`, dan `titik_rute` (kumpulan trayek resmi bus/angkot).
*   **`user_profile.dart`**: Blueprint data profil pengguna (nama, id, role).
*   **`wisata.dart` & `wisata_service.dart`**: Menangani query tabel tempat wisata.
*   **`supabase_config.dart`**: Menaruh variabel *API Key* dan *URL Server* rahasia Supabase Anda.

*(Note: File `bus_service.dart`, `jadwal.dart`, `jadwal_service.dart` sudah bisa dihapus).*

---

## 4. 🎨 Views (`lib/views/`)
Murni berisi elemen-elemen Visual (Warna, Teks, Tombol, Layar). Sama sekali tidak ada logika *Query* ke database di sini.

*   **`splash_screen.dart`**: Halaman animasi awal/logo saat aplikasi pertama kali diklik.
*   **`login.dart` & `register.dart`**: Layar desain form masuk dan pembuatan akun.
*   **`home.dart`**: Layar Utama / Beranda (Dashboard aplikasi).
*   **`navigasi.dart`**: Layar perencanaan awal rute (Pemilihan 'Dari' dan 'Ke mana' serta tombol Mulai Navigasi).
*   **`map_picker.dart`**: Layar pop-up peta full-screen yang memungkinkan Anda men-tap bebas lokasi Custom.
*   **`navigasi_aktif.dart`**: Layar **Paling Rumit** yang memuat Peta *Flutter Map*, menggambar garis biru, render lokasi *Live*, panel info bus di bawah, beserta tombol lonceng alarm.
*   **`detail_po_bus.dart` & `detail_wisata.dart`**: Layar brosur/info lengkap jika sebuah PO Bus atau Tempat Wisata diklik.
*   **`edit_profil.dart` & `profil.dart`**: Tampilan halaman pengaturan akun pengguna.
*   **`halte.dart`**: Layar tab Direktori/List daftar seluruh halte di kota.
*   **`rekomendasi.dart`**: Layar tab rekomendasi jalan-jalan.
*   **`riwayat_perjalanan.dart`**: Layar yang berisi *List* tiket riwayat Anda dari masa lalu.
*   **`perizinan.dart`**: Layar pop-up darurat yang meminta izin (Lokasi GPS / Notifikasi) jika sistem mendeteksi izin HP belum diberikan.
*   **`tentang_aplikasi.dart`**: Halaman informasi pembuat aplikasi dan versi.

---

## 5. 🧩 Templates & Core (`lib/templates/` & `lib/core/`)
Komponen yang dipakai berulang-ulang, dan pengaturan pusat.

*   **`core/theme/app_colors.dart` & `app_theme.dart`**: Menyimpan semua kode warna dan standar ketebalan huruf. Kalau Anda ingin mengubah warna biru (*primary*) aplikasi menjadi hijau, Anda cukup ubah di satu file ini saja, dan seluruh aplikasi akan berubah.
*   **`core/notification_service.dart`**: Kode "Level Inti OS" yang berurusan langsung dengan alarm notifikasi bawaan HP (*Flutter Local Notifications Plugin*).
*   **`templates/header.dart`**: Desain bar bagian atas yang dipakai di hampir semua layar.
*   **`templates/bottom_navbar.dart`**: Desain bar bagian bawah (Menu Navigasi 4 Icon: Beranda, Halte, Rekomendasi, Profil).

---

## 6. 🛠️ Utils (`lib/utils/`)
Kumpulan alat bantu pendukung (*Helper*).

*   **`polyline_utils.dart`**: File berisi rumus Google Polyline Algorithm untuk mengubah String berantakan (contoh: `_p~iF~ps|U_ulLnnqC_mqNvxq`...) menjadi barisan 500 koordinat lintang-bujur di Peta.
*   **`temp_cache.dart`**: *Cache/Memori Sementara* (hanya disimpan di RAM, bukan Database) yang sengaja kita buat agar sistem tetap ingat titik lokasi "Custom" Anda saat navigasi bebas berlangsung.
