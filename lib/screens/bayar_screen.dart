import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/transaksi.dart';
import '../widgets/confirm_dialog.dart';

class BayarScreen extends StatefulWidget {
  final Transaksi transaksi;

  const BayarScreen({super.key, required this.transaksi});

  @override
  State<BayarScreen> createState() => _BayarScreenState();
}

class _BayarScreenState extends State<BayarScreen> {
  final _nominalController = TextEditingController();
  final _tanggalController = TextEditingController();
  DateTime _tanggalBayar = DateTime.now();
  DateTime? _tanggalJanjiBerikutnya;

  @override
  void initState() {
    super.initState();
    _tanggalController.text =
        DateFormat('dd MMMM yyyy', 'id_ID').format(_tanggalBayar);
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _tanggalController.dispose();
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

  String formatTanggal(String date) {
    try {
      final d = DateTime.parse(date);
      return DateFormat('dd MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      return date;
    }
  }

  Future<void> _prosesBayar() async {
    final nominal =
        double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;

    if (nominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nominal pembayaran harus lebih dari 0'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final sisaSetelahBayar = widget.transaksi.sisaHutang - nominal;
    final isLunas = sisaSetelahBayar <= 0;

    String message = 'Proses pembayaran ${formatRupiah(nominal)}?';
    if (isLunas) {
      message += '\n\nNasabah akan dinyatakan LUNAS ✅';
    } else {
      message +=
          '\n\nSisa hutang: ${formatRupiah(sisaSetelahBayar)}';
      if (_tanggalJanjiBerikutnya != null) {
        message +=
            '\nJanji bayar berikutnya: ${DateFormat('dd MMM yyyy', 'id_ID').format(_tanggalJanjiBerikutnya!)}';
      }
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Konfirmasi Pembayaran',
      message: message,
      icon: Icons.payment,
      confirmColor:
          isLunas ? const Color(0xFF4CAF50) : const Color(0xFFD4AF37),
    );

    if (!confirmed) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    await provider.prosesPembayaran(
      transaksi: widget.transaksi,
      nominal: nominal,
      tanggalBayar: _tanggalBayar.toIso8601String().split('T')[0],
      tanggalJanjiBerikutnya: _tanggalJanjiBerikutnya != null
          ? _tanggalJanjiBerikutnya!.toIso8601String().split('T')[0]
          : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLunas
              ? 'Pembayaran lunas! ✅'
              : 'Pembayaran berhasil dicatat'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final nama = provider.getNasabahNama(widget.transaksi.nasabahId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Proses Pembayaran'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Transaksi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      'Nominal Pinjaman',
                      formatRupiah(widget.transaksi.nominalPinjaman)),
                  _buildInfoRow(
                      'Biaya Admin',
                      formatRupiah(widget.transaksi.biayaAdmin)),
                  _buildInfoRow(
                      'Total Harus Bayar',
                      formatRupiah(widget.transaksi.totalHarusBayar)),
                  const Divider(color: Color(0xFFD4AF37), height: 24),
                  _buildInfoRow(
                      'Sudah Dibayar',
                      formatRupiah(widget.transaksi.totalDibayar),
                      color: const Color(0xFF4CAF50)),
                  _buildInfoRow(
                    'Sisa Hutang',
                    formatRupiah(widget.transaksi.sisaHutang),
                    color: const Color(0xFFE53935),
                    isBold: true,
                  ),
                  _buildInfoRow(
                      'Jatuh Tempo',
                      formatTanggal(widget.transaksi.tanggalJatuhTempo)),
                  _buildInfoRow(
                      'Status',
                      widget.transaksi.status.toUpperCase(),
                      color: widget.transaksi.status == 'lunas'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFFB300)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Riwayat Pembayaran
            if (widget.transaksi.riwayatPembayaran.isNotEmpty) ...[
              const Text(
                '📜 Riwayat Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.transaksi.riwayatPembayaran
                  .asMap()
                  .entries
                  .toList()
                  .reversed
                  .map((e) {
                final idx = e.key + 1;
                final p = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '$idx',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatTanggal(p.tanggal),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        formatRupiah(p.nominal),
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Form Pembayaran (only if not lunas)
            if (widget.transaksi.status != 'lunas') ...[
              const Text(
                '💳 Input Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Nominal bayar
              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Nominal Pembayaran (Rp)',
                  labelStyle:
                      TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: Icon(Icons.monetization_on,
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

              const SizedBox(height: 16),

              // Tanggal bayar
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _tanggalBayar,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFD4AF37),
                            surface: Color(0xFF1E293B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggalBayar = picked;
                      _tanggalController.text =
                          DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _tanggalController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Tanggal Pembayaran',
                      labelStyle:
                          TextStyle(color: Colors.white.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.calendar_today,
                          color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tanggal janji berikutnya
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFD4AF37),
                            surface: Color(0xFF1E293B),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _tanggalJanjiBerikutnya = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event,
                          color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Janji Bayar Berikutnya (opsional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _tanggalJanjiBerikutnya != null
                                  ? DateFormat('dd MMMM yyyy', 'id_ID')
                                      .format(_tanggalJanjiBerikutnya!)
                                  : 'Belum dipilih',
                              style: TextStyle(
                                fontSize: 15,
                                color: _tanggalJanjiBerikutnya != null
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _prosesBayar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Proses Pembayaran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
