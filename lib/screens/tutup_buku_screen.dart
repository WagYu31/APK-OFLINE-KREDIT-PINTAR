import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_provider.dart';
import '../models/settings.dart';
import '../widgets/confirm_dialog.dart';
import 'pdf_preview_screen.dart';

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

  Future<bool> _checkActiveTransaksiBeforeProceed() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final activeTransaksi =
        provider.allTransaksi.where((t) => t.status != 'lunas').toList();

    if (activeTransaksi.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: const Color(0xFFE53935).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Masih Ada Transaksi Aktif!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tutup buku tidak dapat dilakukan karena masih terdapat ${activeTransaksi.length} transaksi/nasabah yang belum lunas!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFE53935), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Semua transaksi harus dibersihkan/dilunasi terlebih dahulu sebelum tutup buku.',
                        style: TextStyle(
                          color: Color(0xFFFF8A80),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _prosesTutupBuku() async {
    if (!await _checkActiveTransaksiBeforeProceed()) return;

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
    if (!await _checkActiveTransaksiBeforeProceed()) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final data = _tutupBukuData!;
    final allNasabah = provider.allNasabah;
    final allTransaksi = provider.allTransaksi;

    final pdf = pw.Document();

    String formatTanggal(String isoDate) {
      if (isoDate.isEmpty) return '-';
      try {
        final dt = DateTime.parse(isoDate);
        return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
      } catch (_) {
        return isoDate;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              'Sukron08 - Laporan Tutup Buku & Rekapan Nasabah',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Title Block
            pw.Center(
              child: pw.Text(
                'LAPORAN TUTUP BUKU TAHUN ${data['tahun']}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Sukron08 - Rekapan Data Keuangan & Riwayat Nasabah',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),

            // Summary Table
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📊 RINGKASAN REKAP TUTUP BUKU TAHUN ${data['tahun']}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 8),
                  _pdfRow('Modal Awal', formatRupiah((data['modalAwal'] as num).toDouble())),
                  _pdfRow('Total Keuntungan', formatRupiah((data['totalKeuntungan'] as num).toDouble())),
                  _pdfRow('Total Pinjaman', formatRupiah((data['totalPinjaman'] as num).toDouble())),
                  _pdfRow('Total Pengembalian', formatRupiah((data['totalPengembalian'] as num).toDouble())),
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  _pdfRow('Total Transaksi', '${data['totalTransaksi']}'),
                  _pdfRow('Total Nasabah', '${data['totalNasabah']}'),
                  _pdfRow('Nasabah Baru', '${data['totalNasabahBaru']}'),
                  _pdfRow('Kartu Kuning', '${data['totalKartuKuning']}'),
                  _pdfRow('Kartu Merah', '${data['totalKartuMerah']}'),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1.5, color: PdfColors.black),
            pw.SizedBox(height: 12),

            // Section Header: Nasabah & Riwayat Transaksi
            pw.Text(
              '📋 DATA TRANSAKSI & RIWAYAT SETIAP NASABAH',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Rekapan lengkap seluruh riwayat transaksi untuk setiap nasabah',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),

            // Loop every Nasabah
            ...allNasabah.map((nasabah) {
              final txList = allTransaksi.where((t) => t.nasabahId == nasabah.id).toList();

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 14),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Nasabah Header Row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'NASABAH: ${nasabah.nama.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'No Telp: ${nasabah.nomorTelpon}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                    if (nasabah.kartuKuning || nasabah.kartuMerah || nasabah.diblokir) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Badge Status: ${nasabah.diblokir ? "[DIBLOKIR] " : ""}${nasabah.kartuMerah ? "[KARTU MERAH] " : ""}${nasabah.kartuKuning ? "[KARTU KUNING: ${nasabah.alasanKartuKuning ?? '-'}]" : ""}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                      ),
                    ],
                    pw.SizedBox(height: 6),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 6),

                    // Transaksi List for this Nasabah
                    if (txList.isEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Text(
                          'Belum ada transaksi',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      )
                    else
                      ...txList.asMap().entries.map((txEntry) {
                        final txIndex = txEntry.key + 1;
                        final t = txEntry.value;

                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Header Transaksi
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Pinjaman #$txIndex - Tanggal Pinjam: ${formatTanggal(t.tanggalPinjam)}',
                                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: pw.BoxDecoration(
                                      color: t.status == 'lunas' ? PdfColors.green100 : PdfColors.orange100,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                    child: pw.Text(
                                      t.status.toUpperCase(),
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: t.status == 'lunas' ? PdfColors.green800 : PdfColors.orange900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 4),

                              // Details Row 1: Nominal & Admin
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text('Nominal Pinjam: ${formatRupiah(t.nominalPinjaman)}',
                                        style: const pw.TextStyle(fontSize: 8.5)),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text('Biaya Admin: ${formatRupiah(t.biayaAdmin)}',
                                        style: const pw.TextStyle(fontSize: 8.5)),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 2),
                              // Details Row 2: Harus Bayar, Sisa, Jatuh Tempo
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text('Total Harus Bayar: ${formatRupiah(t.totalHarusBayar)}',
                                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text('Sisa Hutang: ${formatRupiah(t.sisaHutang)}',
                                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.red800)),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text('Tanggal Jatuh Tempo: ${formatTanggal(t.tanggalJatuhTempo)}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),

                              // Table Riwayat Pembayaran (Angsuran)
                              if (t.riwayatPembayaran.isNotEmpty) ...[
                                pw.SizedBox(height: 6),
                                pw.Text('Riwayat Angsuran / Pembayaran:',
                                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 3),
                                pw.Table(
                                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                                  children: [
                                    pw.TableRow(
                                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                      children: [
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('No', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('Tanggal Bayar', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('Nominal Bayar', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('Janji Bayar Berikutnya', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                      ],
                                    ),
                                    ...t.riwayatPembayaran.asMap().entries.toList().reversed.map((pEntry) {
                                      final pIdx = pEntry.key + 1;
                                      final p = pEntry.value;
                                      return pw.TableRow(
                                        children: [
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text('$pIdx', style: const pw.TextStyle(fontSize: 7.5))),
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text(formatTanggal(p.tanggal), style: const pw.TextStyle(fontSize: 7.5))),
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text(formatRupiah(p.nominal), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text(
                                                  p.tanggalJanjiBerikutnya != null
                                                      ? formatTanggal(p.tanggalJanjiBerikutnya!)
                                                      : '-',
                                                  style: const pw.TextStyle(fontSize: 7.5))),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Text(
              'Laporan dicetak otomatis pada: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            title: 'Laporan Tutup Buku ${data['tahun']}',
            pdfBytes: bytes,
            fileName: 'Tutup_Buku_${data['tahun']}.pdf',
          ),
        ),
      );
    }
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

  Future<void> _mulaiTahunBaru() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    final modalBaru =
        double.tryParse(_modalBaruController.text.replaceAll('.', '')) ?? 0;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Mulai Tahun Baru?',
      message:
          'Transaksi akan direset untuk tahun baru. Kartu kuning akan dicabut. Data nasabah tetap aman & tersimpan.',
      icon: Icons.refresh,
      confirmColor: const Color(0xFFD4AF37),
    );

    if (!confirmed) return;

    await provider.resetData(fullReset: false);

    final nextYear = provider.settings.tahunAktif + 1;
    final newSettings = Settings(
      modalAwal: modalBaru > 0 ? modalBaru : provider.settings.modalAwal,
      tahunAktif: nextYear,
    );
    await provider.saveSettings(newSettings);

    if (mounted) {
      provider.switchTab(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tahun baru $nextYear berhasil dimulai! 🎆'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() {
        _tutupBukuData = null;
        _modalBaruController.clear();
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

                // Download/Print PDF & Selesai Row
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text(
                            'Download PDF',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => provider.switchTab(0),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text(
                            'Selesai',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
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

                // Mulai Tahun Baru Option
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _mulaiTahunBaru,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'Mulai Tahun Baru Sekarang',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
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

  Future<void> _exportPdfForData(Map<String, dynamic> data) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final allNasabah = provider.allNasabah;
    final allTransaksi = provider.allTransaksi;

    final pdf = pw.Document();

    String formatTanggal(String isoDate) {
      if (isoDate.isEmpty) return '-';
      try {
        final dt = DateTime.parse(isoDate);
        return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
      } catch (_) {
        return isoDate;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              'Sukron08 - Laporan Tutup Buku & Rekapan Nasabah',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Title Block
            pw.Center(
              child: pw.Text(
                'LAPORAN TUTUP BUKU TAHUN ${data['tahun']}',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Sukron08 - Rekapan Data Keuangan & Riwayat Nasabah',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),

            // Summary Table
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📊 RINGKASAN REKAP TUTUP BUKU TAHUN ${data['tahun']}',
                    style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                  pw.SizedBox(height: 8),
                  _pdfRow('Modal Awal', formatRupiah((data['modalAwal'] as num).toDouble())),
                  _pdfRow('Total Keuntungan', formatRupiah((data['totalKeuntungan'] as num).toDouble())),
                  _pdfRow('Total Pinjaman', formatRupiah((data['totalPinjaman'] as num).toDouble())),
                  _pdfRow('Total Pengembalian', formatRupiah((data['totalPengembalian'] as num).toDouble())),
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 6),
                  _pdfRow('Total Transaksi', '${data['totalTransaksi']}'),
                  _pdfRow('Total Nasabah', '${data['totalNasabah']}'),
                  _pdfRow('Nasabah Baru', '${data['totalNasabahBaru']}'),
                  _pdfRow('Kartu Kuning', '${data['totalKartuKuning']}'),
                  _pdfRow('Kartu Merah', '${data['totalKartuMerah']}'),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1.5, color: PdfColors.black),
            pw.SizedBox(height: 12),

            // Section Header: Nasabah & Riwayat Transaksi
            pw.Text(
              '📋 DATA TRANSAKSI & RIWAYAT SETIAP NASABAH',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Rekapan lengkap seluruh riwayat transaksi untuk setiap nasabah',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 10),

            // Loop every Nasabah
            ...allNasabah.map((nasabah) {
              final txList = allTransaksi.where((t) => t.nasabahId == nasabah.id).toList();

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 14),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.white,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Nasabah Header Row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'NASABAH: ${nasabah.nama.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'No Telp: ${nasabah.nomorTelpon}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                    if (nasabah.kartuKuning || nasabah.kartuMerah || nasabah.diblokir) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Badge Status: ${nasabah.diblokir ? "[DIBLOKIR] " : ""}${nasabah.kartuMerah ? "[KARTU MERAH] " : ""}${nasabah.kartuKuning ? "[KARTU KUNING: ${nasabah.alasanKartuKuning ?? '-'}]" : ""}',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                      ),
                    ],
                    pw.SizedBox(height: 6),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 6),

                    // Transaksi List for this Nasabah
                    if (txList.isEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Text(
                          'Belum ada transaksi',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      )
                    else
                      ...txList.asMap().entries.map((txEntry) {
                        final txIndex = txEntry.key + 1;
                        final t = txEntry.value;

                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          padding: const pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey50,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Header Transaksi
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Pinjaman #$txIndex - Tanggal Pinjam: ${formatTanggal(t.tanggalPinjam)}',
                                    style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: pw.BoxDecoration(
                                      color: t.status == 'lunas' ? PdfColors.green100 : PdfColors.orange100,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                    child: pw.Text(
                                      t.status.toUpperCase(),
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: t.status == 'lunas' ? PdfColors.green800 : PdfColors.orange900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 4),

                              // Details Row 1: Nominal & Admin
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text('Nominal Pinjam: ${formatRupiah(t.nominalPinjaman)}',
                                        style: const pw.TextStyle(fontSize: 8.5)),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text('Biaya Admin: ${formatRupiah(t.biayaAdmin)}',
                                        style: const pw.TextStyle(fontSize: 8.5)),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 2),
                              // Details Row 2: Harus Bayar, Sisa, Jatuh Tempo
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    child: pw.Text('Total Harus Bayar: ${formatRupiah(t.totalHarusBayar)}',
                                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text('Sisa Hutang: ${formatRupiah(t.sisaHutang)}',
                                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.red800)),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text('Tanggal Jatuh Tempo: ${formatTanggal(t.tanggalJatuhTempo)}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),

                              // Table Riwayat Pembayaran (Angsuran)
                              if (t.riwayatPembayaran.isNotEmpty) ...[
                                pw.SizedBox(height: 6),
                                pw.Text('Riwayat Angsuran / Pembayaran:',
                                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                pw.SizedBox(height: 3),
                                pw.Table(
                                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                                  children: [
                                    pw.TableRow(
                                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                                      children: [
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('No', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('Tanggal Bayar', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('Nominal Bayar', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                        pw.Padding(
                                            padding: const pw.EdgeInsets.all(3),
                                            child: pw.Text('Janji Bayar Berikutnya', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                      ],
                                    ),
                                    ...t.riwayatPembayaran.asMap().entries.map((pEntry) {
                                      final pIdx = pEntry.key + 1;
                                      final p = pEntry.value;
                                      return pw.TableRow(
                                        children: [
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text('$pIdx', style: const pw.TextStyle(fontSize: 7.5))),
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text(formatTanggal(p.tanggal), style: const pw.TextStyle(fontSize: 7.5))),
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text(formatRupiah(p.nominal), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                                          pw.Padding(
                                              padding: const pw.EdgeInsets.all(3),
                                              child: pw.Text(
                                                  p.tanggalJanjiBerikutnya != null
                                                      ? formatTanggal(p.tanggalJanjiBerikutnya!)
                                                      : '-',
                                                  style: const pw.TextStyle(fontSize: 7.5))),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 20),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Text(
              'Laporan dicetak otomatis pada: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfPreviewScreen(
            title: 'Laporan Tutup Buku ${data['tahun']}',
            pdfBytes: bytes,
            fileName: 'Tutup_Buku_${data['tahun']}.pdf',
          ),
        ),
      );
    }
  }

  void _showDetailRiwayatTutupBuku(BuildContext context, Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.book,
                            color: Color(0xFFD4AF37),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rekap Tutup Buku ${d['tahun']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Data riwayat rekapitulasi tahunan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.white12),

              // Body Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildRekapRow(
                              '① Modal Awal',
                              formatRupiah((d['modalAwal'] as num).toDouble()),
                            ),
                            _buildRekapRow(
                              '⑮ Total Keuntungan',
                              formatRupiah(
                                  (d['totalKeuntungan'] as num).toDouble()),
                              color: const Color(0xFF4CAF50),
                            ),
                            const Divider(color: Color(0xFFD4AF37), height: 24),
                            _buildRekapRow(
                              '⑬ Total Pinjaman',
                              formatRupiah(
                                  (d['totalPinjaman'] as num).toDouble()),
                            ),
                            _buildRekapRow(
                              '⑭ Total Pengembalian',
                              formatRupiah(
                                  (d['totalPengembalian'] as num).toDouble()),
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            _buildRekapRow(
                              'Total Transaksi',
                              '${d['totalTransaksi']}',
                            ),
                            _buildRekapRow(
                              'Total Nasabah',
                              '${d['totalNasabah']}',
                            ),
                            _buildRekapRow(
                              'Nasabah Baru',
                              '${d['totalNasabahBaru']}',
                            ),
                            _buildRekapRow(
                              '🟡 Kartu Kuning',
                              '${d['totalKartuKuning']}',
                              color: const Color(0xFFFFB300),
                            ),
                            _buildRekapRow(
                              '🔴 Kartu Merah',
                              '${d['totalKartuMerah']}',
                              color: const Color(0xFFE53935),
                            ),
                          ],
                        ),
                      ),
                      // Nasabah Data Breakdown List
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '📋 Data Nasabah & Transaksi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...provider.allNasabah.map((n) {
                        final nTx = provider.allTransaksi
                            .where((t) => t.nasabahId == n.id)
                            .toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    n.nama,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    n.nomorTelpon,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              if (n.kartuKuning || n.kartuMerah || n.diblokir) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (n.diblokir)
                                      const Text('[DIBLOKIR] ', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                    if (n.kartuMerah)
                                      const Text('[KARTU MERAH] ', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                    if (n.kartuKuning)
                                      Text('[KARTU KUNING: ${n.alasanKartuKuning ?? "-"}] ', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (nTx.isEmpty)
                                Text(
                                  'Belum ada transaksi',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 12,
                                  ),
                                )
                              else
                                ...nTx.map((t) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Pinjaman: ${formatRupiah(t.nominalPinjaman)}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          t.status.toUpperCase(),
                                          style: TextStyle(
                                            color: t.status == 'lunas'
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFFF9800),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _exportPdfForData(d);
                                },
                                icon: const Icon(Icons.picture_as_pdf, size: 18),
                                label: Text(
                                  'Download PDF ${d['tahun']}',
                                  style: const TextStyle(
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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  provider.switchTab(0);
                                },
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text(
                                  'Selesai',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  return Column(
    children: snapshot.data!.map((d) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showDetailRiwayatTutupBuku(context, d),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Color(0xFFD4AF37),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tahun ${d['tahun']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Klik untuk lihat detail & PDF',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        formatRupiah(
                            (d['totalKeuntungan'] as num).toDouble()),
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.4),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
