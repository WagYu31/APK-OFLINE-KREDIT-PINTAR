import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/settings.dart';
import '../widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final bool isFirstTime;

  const SettingsScreen({super.key, this.isFirstTime = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _modalController = TextEditingController();
  final _targetController = TextEditingController();
  final _biayaAdminController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.settings.modalAwal > 0) {
      _modalController.text =
          provider.settings.modalAwal.toInt().toString();
    }
    if (provider.settings.targetKeuntungan > 0) {
      _targetController.text =
          provider.settings.targetKeuntungan.toInt().toString();
    }
    final adminRate = provider.settings.biayaAdminPerKelipatan > 0
        ? provider.settings.biayaAdminPerKelipatan
        : 25000.0;
    _biayaAdminController.text = adminRate.toInt().toString();
  }

  @override
  void dispose() {
    _modalController.dispose();
    _targetController.dispose();
    _biayaAdminController.dispose();
    super.dispose();
  }

  String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _saveSettings() async {
    final modal =
        double.tryParse(_modalController.text.replaceAll('.', '')) ?? 0;
    if (modal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Modal awal harus lebih dari 0'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Simpan Pengaturan?',
      message: 'Modal awal: ${formatRupiah(modal)}',
      icon: Icons.settings,
    );

    if (!confirmed) return;

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final target =
          double.tryParse(_targetController.text.replaceAll('.', '')) ?? 0;
      final adminRate =
          double.tryParse(_biayaAdminController.text.replaceAll('.', '')) ?? 25000;

      final settings = Settings(
        modalAwal: modal,
        targetKeuntungan: target,
        biayaAdminPerKelipatan: adminRate > 0 ? adminRate : 25000,
        tahunAktif: DateTime.now().year,
      );
      await provider.saveSettings(settings);

      setState(() => _isSaving = false);

      if (mounted) {
        provider.switchTab(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pengaturan disimpan! ✅'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: widget.isFirstTime
          ? null
          : AppBar(
              title: const Text('Pengaturan'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              foregroundColor: Colors.white,
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isFirstTime) ...[
              const SizedBox(height: 60),
              const Center(
                child: Text(
                  '💰',
                  style: TextStyle(fontSize: 64),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Selamat Datang!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Masukkan modal awal untuk memulai',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ] else ...[
              const SizedBox(height: 20),
              const Text(
                '⚙️ Pengaturan Aplikasi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Atur modal awal, target keuntungan, dan biaya admin',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Modal Awal Input
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modal Awal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total uang yang anda keluarkan untuk bisnis pinjaman',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Target Keuntungan Input
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Target Keuntungan (per tahun)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Berapa keuntungan yang ingin dicapai dalam 1 tahun',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: 'Contoh: 50000000',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Biaya Admin Input
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF42A5F5).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏷️ Biaya Admin (per kelipatan Rp 100.000)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF42A5F5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Besar biaya admin untuk setiap kelipatan pinjaman Rp 100.000 (Dapat diubah kapan saja)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _biayaAdminController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: 'Contoh: 25000',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.15),
                        fontSize: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                            const BorderSide(color: Color(0xFF42A5F5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Backup & Restore Section (Pindah Device / HP Baru)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phonelink_setup,
                          color: Color(0xFFD4AF37), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '📦 Cadangkan & Pindah HP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pindahkan seluruh data transaksi & nasabah ke HP baru tanpa kehilangan data sedikitpun.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Button 1: Cadangkan Data (Ekspor)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final provider =
                            Provider.of<AppProvider>(context, listen: false);
                        final path = await provider.exportBackupFile();
                        if (path != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'File Cadangan Berhasil Dibuat & Siap Bagikan! 📤'),
                              backgroundColor: const Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 20),
                      label: const Text(
                        'Cadangkan Data (Ekspor File / WA)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Button 2: Pulihkan Data (Impor)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Pulihkan Data?',
                          message:
                              'Seluruh data di aplikasi ini akan digantikan dengan data dari file cadangan yang Anda pilih.',
                          icon: Icons.download_rounded,
                          confirmColor: const Color(0xFF4CAF50),
                        );
                        if (!confirmed) return;

                        final provider =
                            Provider.of<AppProvider>(context, listen: false);
                        final success = await provider.importBackupFromFile();
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Pemulihan Data Berhasil! Seluruh Data Siap Digunakan. 🎉'),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Batal atau Format File Cadangan Tidak Valid.'),
                                backgroundColor: const Color(0xFFE53935),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: const Text(
                        'Pulihkan Data (Impor Dari File)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                        side: const BorderSide(
                            color: Color(0xFF4CAF50), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        widget.isFirstTime ? 'Mulai Sekarang 🚀' : 'Simpan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
