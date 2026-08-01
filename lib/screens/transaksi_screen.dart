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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _tanggalJatuhTempo = DateTime.now().add(const Duration(days: 30));

  double _biayaAdmin = 0;
  double _totalBayar = 0;
  double _keuntungan = 0;

  @override
  void dispose() {
    _namaController.dispose();
    _telpController.dispose();
    _nominalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _hitungBiaya() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final rate = provider.settings.biayaAdminPerKelipatan > 0
        ? provider.settings.biayaAdminPerKelipatan
        : 25000.0;
    final nominal =
        double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _biayaAdmin = Transaksi.hitungBiayaAdmin(nominal, rate: rate);
      _totalBayar = Transaksi.hitungTotalBayar(nominal, rate: rate);
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

    // Check if nasabah is selected & blocked
    if (!_isNasabahBaru) {
      if (_selectedNasabah == null) {
        _showError('Silakan cari dan pilih pelanggan terlebih dahulu');
        return;
      }
      if (_selectedNasabah!.kartuMerah || _selectedNasabah!.diblokir) {
        _showError('Nasabah ini terkena Kartu Merah (Diblokir). Tidak bisa membuat transaksi baru.');
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
    _searchController.clear();
    setState(() {
      _searchQuery = '';
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
        final filteredNasabah = provider.allNasabah.where((n) {
          final q = _searchQuery.toLowerCase().trim();
          if (q.isEmpty) return true;
          return n.nama.toLowerCase().contains(q) ||
              n.nomorTelpon.contains(q);
        }).toList();

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
                  // Pilih Pelanggan (dengan Fitur Pencarian Nama)
                  if (_selectedNasabah == null) ...[
                    TextFormField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '🔍 Cari nama atau no. telp nasabah...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFD4AF37),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
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
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.2),
                        ),
                      ),
                      child: filteredNasabah.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'Nasabah tidak ditemukan',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: filteredNasabah.length,
                              separatorBuilder: (_, __) => Divider(
                                color: Colors.white.withOpacity(0.05),
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final n = filteredNasabah[index];
                                final isBlocked = n.kartuMerah || n.diblokir;

                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isBlocked
                                        ? Colors.red.withOpacity(0.2)
                                        : const Color(0xFFD4AF37).withOpacity(0.2),
                                    child: Text(
                                      n.nama.isNotEmpty ? n.nama[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        color: isBlocked
                                            ? Colors.red
                                            : const Color(0xFFD4AF37),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        n.nama,
                                        style: TextStyle(
                                          color: isBlocked ? Colors.white38 : Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          decoration: isBlocked ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      if (isBlocked) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            '⛔ Merah',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    n.nomorTelpon,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(isBlocked ? 0.25 : 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (n.kartuKuning)
                                        const Icon(Icons.warning,
                                            size: 16, color: Color(0xFFFFB300)),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isBlocked ? Icons.lock : Icons.check_circle_outline,
                                        color: isBlocked ? Colors.red : const Color(0xFFD4AF37),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (isBlocked) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '❌ Nasabah "${n.nama}" terkena Kartu Merah (Diblokir). Tidak bisa membuat transaksi baru!',
                                          ),
                                          backgroundColor: const Color(0xFFE53935),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _selectedNasabah = n;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _selectedNasabah!.diblokir
                                ? Colors.red.withOpacity(0.2)
                                : const Color(0xFFD4AF37).withOpacity(0.2),
                            child: Text(
                              _selectedNasabah!.nama.isNotEmpty
                                  ? _selectedNasabah!.nama[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: _selectedNasabah!.diblokir
                                    ? Colors.red
                                    : const Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _selectedNasabah!.nama,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (_selectedNasabah!.diblokir) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.block, size: 16, color: Colors.red),
                                    ],
                                    if (_selectedNasabah!.kartuKuning) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.warning,
                                          size: 16, color: Color(0xFFFFB300)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedNasabah!.nomorTelpon,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedNasabah = null;
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16, color: Color(0xFFD4AF37)),
                            label: const Text(
                              'Ganti',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            'Total Pinjaman', formatRupiah(double.tryParse(_nominalController.text.replaceAll('.', '')) ?? 0)),
                        _buildCalcRow(
                            'Biaya Admin (25rb/100rb)', formatRupiah(_biayaAdmin)),
                        const Divider(
                          color: Color(0xFFD4AF37),
                          height: 24,
                        ),
                        _buildCalcRow(
                          'Estimasi Pengembalian',
                          formatRupiah(_totalBayar),
                          isBold: true,
                        ),
                        _buildCalcRow(
                          'Estimasi Keuntungan',
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
