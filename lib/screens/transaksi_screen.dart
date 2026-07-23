import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/transaksi.dart';
import '../models/nasabah.dart';
import '../widgets/confirm_dialog.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  bool _isNasabahBaru = true;
  Nasabah? _selectedNasabah;
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _telpController = TextEditingController();
  final _nominalController = TextEditingController();
  DateTime _tanggalJatuhTempo = DateTime.now().add(const Duration(days: 30));

  double _biayaAdmin = 0;
  double _totalBayar = 0;
  double _keuntungan = 0;

  @override
  void dispose() {
    _namaController.dispose();
    _telpController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  void _hitungBiaya() {
    final nominal =
        double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _biayaAdmin = Transaksi.hitungBiayaAdmin(nominal);
      _totalBayar = Transaksi.hitungTotalBayar(nominal);
      _keuntungan = _biayaAdmin;
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

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalJatuhTempo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        _tanggalJatuhTempo = picked;
      });
    }
  }

  Future<void> _submitTransaksi() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal =
        double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;
    if (nominal <= 0) {
      _showError('Nominal pinjaman harus lebih dari 0');
      return;
    }

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Check if nasabah is blocked
    if (!_isNasabahBaru && _selectedNasabah != null) {
      if (_selectedNasabah!.diblokir) {
        _showError('Nasabah ini sedang diblokir (Kartu Merah). Tidak bisa membuat transaksi baru.');
        return;
      }
    }

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Konfirmasi Transaksi',
      message:
          'Buat transaksi baru?\n\nNominal: ${formatRupiah(nominal)}\nBiaya Admin: ${formatRupiah(_biayaAdmin)}\nTotal Bayar: ${formatRupiah(_totalBayar)}\nKeuntungan: ${formatRupiah(_keuntungan)}',
      icon: Icons.receipt_long,
    );

    if (!confirmed) return;

    int nasabahId;

    if (_isNasabahBaru) {
      final nasabah = Nasabah(
        nama: _namaController.text.trim(),
        nomorTelpon: _telpController.text.trim(),
      );
      nasabahId = await provider.addNasabah(nasabah);
    } else {
      nasabahId = _selectedNasabah!.id!;
    }

    final transaksi = Transaksi(
      nasabahId: nasabahId,
      tanggalPinjam: DateTime.now().toIso8601String().split('T')[0],
      nominalPinjaman: nominal,
      biayaAdmin: _biayaAdmin,
      totalHarusBayar: _totalBayar,
      tanggalJatuhTempo: _tanggalJatuhTempo.toIso8601String().split('T')[0],
    );

    await provider.addTransaksi(transaksi);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaksi berhasil dibuat! ✅'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _resetForm();
    }
  }

  void _resetForm() {
    _namaController.clear();
    _telpController.clear();
    _nominalController.clear();
    setState(() {
      _selectedNasabah = null;
      _biayaAdmin = 0;
      _totalBayar = 0;
      _keuntungan = 0;
      _tanggalJatuhTempo = DateTime.now().add(const Duration(days: 30));
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  '📝 Buat Transaksi Baru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat transaksi pinjaman baru untuk nasabah',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle Nasabah Baru / Pelanggan
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _isNasabahBaru = true;
                            _selectedNasabah = null;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _isNasabahBaru
                                  ? const Color(0xFFD4AF37)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '👤 Nasabah Baru',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isNasabahBaru
                                      ? Colors.black
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _isNasabahBaru = false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !_isNasabahBaru
                                  ? const Color(0xFFD4AF37)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '🔄 Pelanggan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !_isNasabahBaru
                                      ? Colors.black
                                      : Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Nasabah Baru form
                if (_isNasabahBaru) ...[
                  _buildTextField(
                    controller: _namaController,
                    label: 'Nama Nasabah',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v!.isEmpty ? 'Nama harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _telpController,
                    label: 'Nomor Telpon / WhatsApp',
                    icon: Icons.phone_android,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.isEmpty ? 'Nomor telepon harus diisi' : null,
                  ),
                ] else ...[
                  // Pilih Pelanggan
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Nasabah>(
                        isExpanded: true,
                        hint: Text(
                          'Pilih Pelanggan',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        value: _selectedNasabah,
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        items: provider.allNasabah
                            .map((n) => DropdownMenuItem<Nasabah>(
                                  value: n,
                                  child: Row(
                                    children: [
                                      Text(n.nama),
                                      if (n.diblokir) ...[
                                        const SizedBox(width: 8),
                                        const Icon(Icons.block,
                                            size: 14, color: Colors.red),
                                      ],
                                      if (n.kartuKuning) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.warning,
                                            size: 14,
                                            color: Color(0xFFFFB300)),
                                      ],
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedNasabah = v),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Nominal Pinjaman
                _buildTextField(
                  controller: _nominalController,
                  label: 'Nominal Pinjaman (Rp)',
                  icon: Icons.monetization_on_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => _hitungBiaya(),
                  validator: (v) =>
                      v!.isEmpty ? 'Nominal harus diisi' : null,
                ),

                const SizedBox(height: 16),

                // Tanggal Jatuh Tempo
                GestureDetector(
                  onTap: () => _selectDate(context),
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
                        Icon(Icons.calendar_today,
                            color: Colors.white.withOpacity(0.5), size: 22),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Jatuh Tempo',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM yyyy', 'id_ID')
                                  .format(_tanggalJatuhTempo),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Kalkulasi otomatis
                if (_nominalController.text.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD4AF37).withOpacity(0.12),
                          const Color(0xFFD4AF37).withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '💰 Kalkulasi Otomatis',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCalcRow(
                            '⑬ Total Pinjaman', formatRupiah(double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0)),
                        _buildCalcRow(
                            'Biaya Admin (25rb/100rb)', formatRupiah(_biayaAdmin)),
                        const Divider(
                          color: Color(0xFFD4AF37),
                          height: 24,
                        ),
                        _buildCalcRow(
                          '⑭ Estimasi Pengembalian',
                          formatRupiah(_totalBayar),
                          isBold: true,
                        ),
                        _buildCalcRow(
                          '⑮ Estimasi Keuntungan',
                          formatRupiah(_keuntungan),
                          color: const Color(0xFF4CAF50),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitTransaksi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Selesai ✓',
                      style: TextStyle(
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
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
    );
  }

  Widget _buildCalcRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
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
