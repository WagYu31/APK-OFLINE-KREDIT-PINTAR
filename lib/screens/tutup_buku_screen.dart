import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_provider.dart';
import '../models/settings.dart';
import '../widgets/confirm_dialog.dart';

class TutupBukuScreen extends StatefulWidget {
  const TutupBukuScreen({super.key});

  @override
  State<TutupBukuScreen> createState() => _TutupBukuScreenState();
}

class _TutupBukuScreenState extends State<TutupBukuScreen> {
  Map<String, dynamic>? _tutupBukuData;
  bool _isProcessing = false;
  final _modalBaruController = TextEditingController();

  String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _prosesTutupBuku() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Tutup Buku?',
      message:
          'Apakah anda yakin ingin menutup buku tahun ${provider.settings.tahunAktif}?\n\nSemua data akan direkap.',
      icon: Icons.book,
      confirmColor: const Color(0xFFD4AF37),
    );

    if (!confirmed) return;

    setState(() => _isProcessing = true);

    try {
      final data = await provider.generateTutupBuku();
      setState(() {
        _tutupBukuData = data;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _exportPdf() async {
    if (_tutupBukuData == null) return;

    final pdf = pw.Document();
    final data = _tutupBukuData!;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'LAPORAN TUTUP BUKU ${data['tahun']}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Kredit Pintar - Manajemen Pinjaman',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 20),
              _pdfRow('Modal Awal',
                  formatRupiah((data['modalAwal'] as num).toDouble())),
              _pdfRow('Total Keuntungan',
                  formatRupiah((data['totalKeuntungan'] as num).toDouble())),
              _pdfRow('Total Pinjaman',
                  formatRupiah((data['totalPinjaman'] as num).toDouble())),
              _pdfRow('Total Pengembalian',
                  formatRupiah((data['totalPengembalian'] as num).toDouble())),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              _pdfRow('Total Transaksi', '${data['totalTransaksi']}'),
              _pdfRow('Total Nasabah', '${data['totalNasabah']}'),
              _pdfRow('Nasabah Baru', '${data['totalNasabahBaru']}'),
              _pdfRow('Kartu Kuning', '${data['totalKartuKuning']}'),
              _pdfRow('Kartu Merah', '${data['totalKartuMerah']}'),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Dicetak: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Tutup_Buku_${data['tahun']}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _resetData(bool fullReset) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final modalBaru =
        double.tryParse(_modalBaruController.text.replaceAll('.', '')) ?? 0;

    final confirmed = await ConfirmDialog.show(
      context,
      title: fullReset ? 'Reset Semua Data?' : 'Mulai Tahun Baru?',
      message: fullReset
          ? 'SEMUA data nasabah & transaksi akan dihapus. Aksi ini tidak bisa dibatalkan!'
          : 'Transaksi akan direset. Kartu kuning akan dicabut. Data nasabah tetap ada.',
      icon: fullReset ? Icons.delete_forever : Icons.refresh,
      confirmColor: fullReset
          ? const Color(0xFFE53935)
          : const Color(0xFFD4AF37),
    );

    if (!confirmed) return;

    await provider.resetData(fullReset: fullReset);

    // Save new settings
    final newSettings = Settings(
      modalAwal: modalBaru > 0 ? modalBaru : provider.settings.modalAwal,
      tahunAktif: DateTime.now().year,
    );
    await provider.saveSettings(newSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data berhasil direset! ✅'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {
        _tutupBukuData = null;
      });
    }
  }

  @override
  void dispose() {
    _modalBaruController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📚 Tutup Buku Tahunan',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rekap data tahun ${provider.settings.tahunAktif} dan mulai tahun baru',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),

              // Tutup Buku button
              if (_tutupBukuData == null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _prosesTutupBuku,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.book),
                    label: Text(
                      _isProcessing ? 'Memproses...' : 'Tutup Buku Sekarang',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],

              // Hasil Tutup Buku
              if (_tutupBukuData != null) ...[
                Container(
                  width: double.infinity,
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
                    children: [
                      const Text(
                        '📊 Rekap Tutup Buku',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      Text(
                        'Tahun ${_tutupBukuData!['tahun']}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildRekapRow(
                        '① Modal Awal',
                        formatRupiah(
                            (_tutupBukuData!['modalAwal'] as num).toDouble()),
                      ),
                      _buildRekapRow(
                        '⑮ Total Keuntungan',
                        formatRupiah(
                            (_tutupBukuData!['totalKeuntungan'] as num)
                                .toDouble()),
                        color: const Color(0xFF4CAF50),
                      ),
                      const Divider(color: Color(0xFFD4AF37), height: 24),
                      _buildRekapRow(
                        '⑬ Total Pinjaman',
                        formatRupiah(
                            (_tutupBukuData!['totalPinjaman'] as num)
                                .toDouble()),
                      ),
                      _buildRekapRow(
                        '⑭ Total Pengembalian',
                        formatRupiah(
                            (_tutupBukuData!['totalPengembalian'] as num)
                                .toDouble()),
                      ),
                      const Divider(
                          color: Colors.white24, height: 24),
                      _buildRekapRow(
                        'Total Transaksi',
                        '${_tutupBukuData!['totalTransaksi']}',
                      ),
                      _buildRekapRow(
                        'Total Nasabah',
                        '${_tutupBukuData!['totalNasabah']}',
                      ),
                      _buildRekapRow(
                        'Nasabah Baru',
                        '${_tutupBukuData!['totalNasabahBaru']}',
                      ),
                      _buildRekapRow(
                        '🟡 Kartu Kuning',
                        '${_tutupBukuData!['totalKartuKuning']}',
                        color: const Color(0xFFFFB300),
                      ),
                      _buildRekapRow(
                        '🔴 Kartu Merah',
                        '${_tutupBukuData!['totalKartuMerah']}',
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Download/Print PDF
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text(
                      'Download / Print PDF',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

                const SizedBox(height: 28),

                // Input Modal Baru
                const Text(
                  '💰 Modal Tahun Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modalBaruController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Modal Awal Tahun Baru (Rp)',
                    labelStyle:
                        TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.account_balance,
                        color: Colors.white.withOpacity(0.4)),
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

                const SizedBox(height: 20),

                // Reset options
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _resetData(false),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Mulai\nTahun Baru',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD4AF37),
                            side: const BorderSide(
                                color: Color(0xFFD4AF37)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _resetData(true),
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: const Text(
                            'Reset\nSemua Data',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE53935),
                            side: const BorderSide(
                                color: Color(0xFFE53935)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              // Riwayat Tutup Buku
              const Text(
                '📜 Riwayat Tutup Buku',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: provider.getRiwayatTutupBuku(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada riwayat tutup buku',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.map((d) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tahun ${d['tahun']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatRupiah(
                                  (d['totalKeuntungan'] as num).toDouble()),
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRekapRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
