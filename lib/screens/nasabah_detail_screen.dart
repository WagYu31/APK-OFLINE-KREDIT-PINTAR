import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_provider.dart';
import '../models/nasabah.dart';
import '../models/transaksi.dart';
import '../widgets/card_badge.dart';
import '../widgets/confirm_dialog.dart';
import 'bayar_screen.dart';
import 'pdf_preview_screen.dart';

class NasabahDetailScreen extends StatefulWidget {
  final Nasabah nasabah;

  const NasabahDetailScreen({super.key, required this.nasabah});

  @override
  State<NasabahDetailScreen> createState() => _NasabahDetailScreenState();
}

class _NasabahDetailScreenState extends State<NasabahDetailScreen> {
  List<Transaksi> _transaksiList = [];
  late Nasabah _nasabah;

  @override
  void initState() {
    super.initState();
    _nasabah = widget.nasabah;
    _loadTransaksi();
  }

  Future<void> _loadTransaksi() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final transaksi =
        await provider.getTransaksiByNasabah(_nasabah.id!);
    setState(() {
      _transaksiList = transaksi;
    });
  }

  String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String formatTanggal(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('dd MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      return date;
    }
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    final totalPinjaman = _transaksiList.fold(0.0, (sum, t) => sum + t.nominalPinjaman);
    final totalHarusBayar = _transaksiList.fold(0.0, (sum, t) => sum + t.totalHarusBayar);
    final totalKeuntungan = _transaksiList.fold(0.0, (sum, t) => sum + t.biayaAdmin);
    final totalSisaHutang = _transaksiList.fold(0.0, (sum, t) => sum + t.sisaHutang);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Text(
              'Sukron08 - Laporan Rekapan Transaksi Nasabah',
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
            // Title Header
            pw.Center(
              child: pw.Text(
                'REKAPAN TRANSAKSI NASABAH',
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
                'Sukron08 - Laporan Riwayat Pinjaman & Pembayaran',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 10),

            // Profile Info Box
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
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'NAMA NASABAH: ${_nasabah.nama.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'No Telp: ${_nasabah.nomorTelpon}',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  if (_nasabah.kartuKuning || _nasabah.kartuMerah || _nasabah.diblokir) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Status Badge: ${_nasabah.diblokir ? "[DIBLOKIR] " : ""}${_nasabah.kartuMerah ? "[KARTU MERAH] " : ""}${_nasabah.kartuKuning ? "[KARTU KUNING: ${_nasabah.alasanKartuKuning ?? '-'}]" : ""}',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 6),

                  // Summary Row
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Pinjaman:', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text(formatRupiah(totalPinjaman), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Keuntungan:', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text(formatRupiah(totalKeuntungan), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Harus Bayar:', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text(formatRupiah(totalHarusBayar), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Sisa Hutang Aktif:', style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            pw.Text(formatRupiah(totalSisaHutang), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Text(
              '📋 DAFTAR RIWAYAT TRANSAKSI (${_transaksiList.length} Transaksi)',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 8),

            if (_transaksiList.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                alignment: pw.Alignment.center,
                child: pw.Text('Belum ada riwayat transaksi.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              )
            else
              ..._transaksiList.asMap().entries.map((txEntry) {
                final index = txEntry.key + 1;
                final t = txEntry.value;

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header Transaksi
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Pinjaman #$index - Tanggal Pinjam: ${formatTanggal(t.tanggalPinjam)}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
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
                      pw.SizedBox(height: 6),

                      // Details Grid
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Text('Nominal Pinjam: ${formatRupiah(t.nominalPinjaman)}',
                                style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                          pw.Expanded(
                            child: pw.Text('Keuntungan/Admin: ${formatRupiah(t.biayaAdmin)}',
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.green800)),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
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
                      pw.Text('Jatuh Tempo: ${formatTanggal(t.tanggalJatuhTempo)}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800)),

                      // Table Riwayat Pembayaran / Angsuran
                      if (t.riwayatPembayaran.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text('Riwayat Pembayaran / Angsuran:',
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

            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 6),
            pw.Text(
              'Dicetak otomatis pada: ${DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(DateTime.now())}',
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
            title: 'Laporan ${_nasabah.nama}',
            pdfBytes: bytes,
            fileName: 'Rekapan_${_nasabah.nama.replaceAll(' ', '_')}.pdf',
          ),
        ),
      );
    }
  }
  Future<void> _showEditDialog(AppProvider provider) async {
    final namaController = TextEditingController(text: _nasabah.nama);
    final teleponController = TextEditingController(text: _nasabah.nomorTelpon);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFFD4AF37), size: 22),
            SizedBox(width: 10),
            Text(
              'Edit Data Nasabah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(Icons.person, color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: teleponController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nomor Telepon',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                prefixIcon: Icon(Icons.phone, color: Colors.white.withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      final newNama = namaController.text.trim();
      final newTelpon = teleponController.text.trim();

      if (newNama.isEmpty || newTelpon.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nama dan nomor telepon tidak boleh kosong'),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      _nasabah.nama = newNama;
      _nasabah.nomorTelpon = newTelpon;
      await provider.updateNasabah(_nasabah);
      await _loadTransaksi();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data nasabah berhasil diupdate ✅'),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {});
      }
    }

    namaController.dispose();
    teleponController.dispose();
  }

  Future<void> _showKartuKuningDialog(AppProvider provider) async {
    if (_nasabah.kartuKuning) {
      // Cabut Kartu Kuning
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Cabut Kartu Kuning?',
        message: 'Cabut Kartu Kuning dari ${_nasabah.nama}?',
        icon: Icons.warning_rounded,
        confirmColor: const Color(0xFFFFB300),
      );
      if (confirmed) {
        await provider.toggleKartuKuning(_nasabah);
        await _loadTransaksi();
        if (mounted) setState(() {});
      }
      return;
    }

    // Beri Kartu Kuning dengan Alasan
    String selectedReason = 'Pelunasan kurang';
    final customReasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFB300),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Beri Kartu Kuning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih alasan memberikan Kartu Kuning untuk ${_nasabah.nama}:',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  
                  // Opsi 1: Pelunasan kurang
                  _buildReasonTile(
                    title: 'Pelunasan kurang',
                    value: 'Pelunasan kurang',
                    groupValue: selectedReason,
                    onChanged: (val) => setDialogState(() => selectedReason = val!),
                  ),
                  
                  // Opsi 2: Tidak tepat janji tanggal pelunasan
                  _buildReasonTile(
                    title: 'Tidak tepat janji tanggal pelunasan',
                    value: 'Tidak tepat janji tanggal pelunasan',
                    groupValue: selectedReason,
                    onChanged: (val) => setDialogState(() => selectedReason = val!),
                  ),

                  // Opsi 3: Lainnya
                  _buildReasonTile(
                    title: 'Lainnya',
                    value: 'Lainnya',
                    groupValue: selectedReason,
                    onChanged: (val) => setDialogState(() => selectedReason = val!),
                  ),

                  if (selectedReason == 'Lainnya') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: customReasonController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan alasan lainnya...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFB300)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(
                  'Batal',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  String finalReason = selectedReason;
                  if (selectedReason == 'Lainnya') {
                    final text = customReasonController.text.trim();
                    finalReason = text.isNotEmpty ? text : 'Lainnya';
                  }
                  Navigator.pop(ctx, finalReason);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    customReasonController.dispose();

    if (result != null) {
      await provider.toggleKartuKuning(_nasabah, alasan: result);
      await _loadTransaksi();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kartu Kuning diberikan: $result ⚠️'),
            backgroundColor: const Color(0xFFFFB300),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() {});
      }
    }
  }

  Widget _buildReasonTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFB300).withOpacity(0.12)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFB300)
              : Colors.transparent,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: const Color(0xFFFFB300),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        dense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    // Refresh nasabah data from provider
    final updated = provider.getNasabahFromList(_nasabah.id!);
    if (updated != null) _nasabah = updated;

    final hasActiveTransaksi =
        _transaksiList.any((t) => t.status != 'lunas');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: Text(_nasabah.nama),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // Blokir / Buka Blokir
          if (_nasabah.kartuMerah || _nasabah.diblokir)
            IconButton(
              icon: Icon(
                _nasabah.diblokir ? Icons.lock_open : Icons.lock,
                color: _nasabah.diblokir
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE53935),
              ),
              onPressed: () async {
                final action =
                    _nasabah.diblokir ? 'Buka Blokir' : 'Blokir';
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: '$action Nasabah?',
                  message: '$action ${_nasabah.nama}?',
                  icon: _nasabah.diblokir ? Icons.lock_open : Icons.block,
                  confirmColor: _nasabah.diblokir
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFE53935),
                );
                if (confirmed) {
                  await provider.toggleBlokir(_nasabah);
                  await _loadTransaksi();
                }
              },
            ),
          // Export PDF button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF42A5F5)),
            onPressed: _exportPdf,
            tooltip: 'Export PDF',
          ),
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
            onPressed: () => _showEditDialog(provider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransaksi,
        color: const Color(0xFFD4AF37),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _nasabah.diblokir
                        ? const Color(0xFFE53935).withOpacity(0.3)
                        : const Color(0xFFD4AF37).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _nasabah.diblokir
                              ? [
                                  const Color(0xFFE53935),
                                  const Color(0xFFB71C1C)
                                ]
                              : [
                                  const Color(0xFFD4AF37),
                                  const Color(0xFFB8860B)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Center(
                        child: Text(
                          _nasabah.nama.isNotEmpty
                              ? _nasabah.nama[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name + Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _nasabah.nama,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        CardBadge(
                          isKuning: _nasabah.kartuKuning,
                          isMerah: _nasabah.kartuMerah,
                          isDiblokir: _nasabah.diblokir,
                          onKuningTap: () => _showKartuKuningDialog(provider),
                          onMerahTap: () async {
                            final action = _nasabah.kartuMerah
                                ? 'Cabut Kartu Merah'
                                : 'Beri Kartu Merah';
                            final confirmed = await ConfirmDialog.show(
                              context,
                              title: '$action?',
                              message: '$action untuk ${_nasabah.nama}?',
                              icon: Icons.block_rounded,
                              confirmColor: const Color(0xFFE53935),
                            );
                            if (confirmed) {
                              await provider.toggleKartuMerah(_nasabah);
                              await _loadTransaksi();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _nasabah.nomorTelpon,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),

                    if (_nasabah.kartuKuning && _nasabah.alasanKartuKuning != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB300), size: 16),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Kartu Kuning: ${_nasabah.alasanKartuKuning}',
                                style: const TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_nasabah.diblokir) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🔒 NASABAH DIBLOKIR',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],

                    // Action Buttons Row (Edit & Export PDF)
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () => _showEditDialog(provider),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit Data', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFD4AF37),
                                side: const BorderSide(color: Color(0xFFD4AF37)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _exportPdf,
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text('Export PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF42A5F5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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

              const SizedBox(height: 28),

              // Status Indicator
              if (!hasActiveTransaksi && _transaksiList.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF42A5F5).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, color: Color(0xFF42A5F5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bulan ini belum ada transaksi. Hubungi untuk follow-up!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Riwayat Transaksi
              const Text(
                '📋 Riwayat Transaksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              if (_transaksiList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._transaksiList.map((t) => _buildTransaksiCard(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransaksiCard(Transaksi transaksi) {
    final isLunas = transaksi.status == 'lunas';
    final isHutang = transaksi.status == 'sebagian';
    final cardColor = isLunas
        ? const Color(0xFF4CAF50)
        : isHutang
            ? const Color(0xFFE53935)
            : const Color(0xFFFFB300);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLunas
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BayarScreen(transaksi: transaksi),
                    ),
                  );
                  _loadTransaksi();
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            transaksi.status.toUpperCase(),
                            style: TextStyle(
                              color: cardColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatTanggal(transaksi.tanggalPinjam),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (isLunas)
                      const Icon(Icons.check_circle,
                          color: Color(0xFF4CAF50), size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailCol(
                        'Pinjaman', formatRupiah(transaksi.nominalPinjaman)),
                    _buildDetailCol(
                        'Total Bayar', formatRupiah(transaksi.totalHarusBayar)),
                    _buildDetailCol(
                      isHutang ? 'Sisa' : 'Keuntungan',
                      isHutang
                          ? formatRupiah(transaksi.sisaHutang)
                          : formatRupiah(transaksi.biayaAdmin),
                      color: isHutang
                          ? const Color(0xFFE53935)
                          : const Color(0xFF4CAF50),
                    ),
                  ],
                ),
                if (isHutang && transaksi.tanggalJanjiBerikutnya != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📅 Janji bayar: ${formatTanggal(transaksi.tanggalJanjiBerikutnya!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCol(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }
}
