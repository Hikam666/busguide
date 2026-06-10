import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../controllers/profil_controller.dart';
import '../templates/header.dart';

//Data profil diambil,diperbarui dri ProfilController
class EditProfilScreen extends StatefulWidget {
  const EditProfilScreen({super.key});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  final _namaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();

  @override
  void initState() { //Data awal form perlu diisi saat halaman pertama dibuka
    super.initState();
    //Ambil data profil, isi form otomatis
    final profilCtrl = context.read<ProfilController>();
    _namaController.text = profilCtrl.nama;
    _noHpController.text = profilCtrl.noHp;
    _alamatController.text = profilCtrl.alamat;
  }

  @override
  void dispose() { //Menggunakan resource memori yg perlu dibersihkan
    _namaController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async { //Pilih gambar dri galeri,unggah
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path); //Ubah path gambar ke objek file
      if (!mounted) return;
      final profilCtrl = context.read<ProfilController>();
      await profilCtrl.uploadAvatar(file); //Kirim gambar ke ProfilController utk unggah ke backend
      
      if (mounted) {
        final error = profilCtrl.error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui')),
          );
        }
      }
    }
  }

  Future<void> _simpan() async { //Simpan data profil ke server
    final nama = _namaController.text.trim();
    final noHp = _noHpController.text.trim();
    final alamat = _alamatController.text.trim();

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    final profilCtrl = context.read<ProfilController>();
    await profilCtrl.updateProfile(
      newNama: nama,
      newNoHp: noHp.isEmpty ? null : noHp,
      newAlamat: alamat.isEmpty ? null : alamat,
    );

    if (mounted) {
      final error = profilCtrl.error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        Navigator.pop(context); // Kembali ke profil
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Edit Profil', showBack: true, showNotification: false),
      body: Consumer<ProfilController>( //Perubahan pada Profilcontroller
        builder: (context, ctrl, _) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Foto Profil ───────────────────────────
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary,
                                backgroundImage: ctrl.profile?.avatarUrl != null
                                    ? NetworkImage(ctrl.profile!.avatarUrl!)
                                    : null,
                                child: ctrl.profile?.avatarUrl == null
                                    ? Text(
                                        ctrl.initials,
                                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              GestureDetector(
                                onTap: ctrl.isLoading ? null : _pickAndUploadImage,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.camera_alt, color: AppColors.primary, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Text(
                          'Nama Lengkap',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _namaController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama lengkap',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'No. Telepon / HP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _noHpController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Alamat Lengkap',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _alamatController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Masukkan alamat lengkap rumah / domisili',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Email (Tidak dapat diubah)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: ctrl.email,
                          readOnly: true,
                          style: const TextStyle(color: Colors.grey),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: ctrl.isLoading ? null : _simpan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: ctrl.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
