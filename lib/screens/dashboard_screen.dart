import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/transaksi.dart';
import '../widgets/stat_card.dart';
import '../widgets/card_badge.dart';
import '../widgets/confirm_dialog.dart';
import 'bayar_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showAllJatuhTempo = false;
  bool _showAllHutang = false;

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

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.statistik;
        final jatuhTempo = provider.transaksiJatuhTempo;
        final hutang = provider.transaksiHutang;

        final displayedJatuhTempo = _showAllJatuhTempo
            ? jatuhTempo
            : jatuhTempo.take(3).toList();

        final displayedHutang = _showAllHutang
            ? hutang
            : hutang.take(3).toList();

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD4AF37),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.refreshData,
          color: const Color(0xFFD4AF37),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ① Target Keuntungan Card
                _buildTargetCard(stats),
                const SizedBox(height: 24),

                // Stats Grid
                _buildStatsGrid(stats, provider, context),
                const SizedBox(height: 28),

                // ③ Tabel Jatuh Tempo (3 hari)
                _buildSectionHeader(
                  '⏰ Jatuh Tempo',
                  '${jatuhTempo.length} nasabah',
                  const Color(0xFFFFB300),
                ),
                const SizedBox(height: 12),
                if (jatuhTempo.isEmpty)
                  _buildEmptyState(
                    'Tidak ada nasabah jatuh tempo',
                    Icons.check_circle_outline,
                    const Color(0xFF4CAF50),
                  )
                else ...[
                  ...displayedJatuhTempo.map((t) => _buildTransaksiCard(
                        context, t, provider,
                        isJatuhTempo: true)),
                  if (jatuhTempo.length > 3) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllJatuhTempo = !_showAllJatuhTempo;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFB300).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showAllJatuhTempo
                                  ? 'Sembunyikan Sebagian'
                                  : 'Lihat Semua (${jatuhTempo.length} Nasabah)',
                              style: const TextStyle(
                                color: Color(0xFFFFB300),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _showAllJatuhTempo
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFFFFB300),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 28),

                // ⑥ Tabel Punya Hutang
                _buildSectionHeader(
                  '💰 Punya Hutang',
                  '${hutang.length} nasabah',
                  const Color(0xFFE53935),
                ),
                const SizedBox(height: 12),
                if (hutang.isEmpty)
                  _buildEmptyState(
                    'Tidak ada nasabah punya hutang',
                    Icons.sentiment_satisfied_alt,
                    const Color(0xFF4CAF50),
                  )
                else ...[
                  ...displayedHutang.map((t) => _buildTransaksiCard(
                        context, t, provider,
                        isHutang: true)),
                  if (hutang.length > 3) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllHutang = !_showAllHutang;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showAllHutang
                                  ? 'Sembunyikan Sebagian'
                                  : 'Lihat Semua (${hutang.length} Nasabah)',
                              style: const TextStyle(
                                color: Color(0xFFE53935),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _showAllHutang
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFFE53935),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTargetCard(Map<String, dynamic> stats) {
    final persen = (stats['persenTarget'] ?? 0.0) as double;
    final modalAwal = (stats['modalAwal'] ?? 0.0) as double;
    final keuntungan = (stats['totalKeuntungan'] ?? 0.0) as double;
    final targetKeuntungan = (stats['targetKeuntungan'] ?? 0.0) as double;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Target Tercapai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(keuntungan),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: persen >= 100
                      ? const Color(0xFF4CAF50).withOpacity(0.2)
                      : const Color(0xFFD4AF37).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${persen.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: persen >= 100
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFD4AF37),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (persen / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                persen >= 100
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFD4AF37),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTargetInfo('Target', formatRupiah(targetKeuntungan)),
              _buildTargetInfo('Tercapai', formatRupiah(keuntungan)),
              _buildTargetInfo('Modal', formatRupiah(modalAwal)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
      Map<String, dynamic> stats, AppProvider provider, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Pinjaman',
            value: formatRupiah((stats['totalPinjaman'] ?? 0.0) as double),
            icon: Icons.account_balance_wallet,
            color: const Color(0xFFAB47BC),
            onTap: () => _showTransaksiAktifModal(context, provider),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            title: 'Total Pengembalian',
            value: formatRupiah((stats['totalPengembalian'] ?? 0.0) as double),
            icon: Icons.payments_outlined,
            color: const Color(0xFF66BB6A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatCard(
            title: 'Transaksi Aktif',
            value: '${stats['totalTransaksiAktif'] ?? 0}',
            icon: Icons.receipt_long,
            color: const Color(0xFF42A5F5),
            onTap: () => _showTransaksiAktifModal(context, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaksiCard(
    BuildContext context,
    Transaksi transaksi,
    AppProvider provider, {
    bool isJatuhTempo = false,
    bool isHutang = false,
  }) {
    final nama = provider.getNasabahNama(transaksi.nasabahId);
    final nasabah = provider.getNasabahFromList(transaksi.nasabahId);
    final cardColor =
        isHutang ? const Color(0xFFE53935) : const Color(0xFFFFB300);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withOpacity(0.12),
            cardColor.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BayarScreen(transaksi: transaksi),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isHutang
                                  ? Icons.warning_rounded
                                  : Icons.access_time_rounded,
                              color: cardColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (nasabah != null)
                                  CardBadge(
                                    isKuning: nasabah.kartuKuning,
                                    isMerah: nasabah.kartuMerah,
                                    isDiblokir: nasabah.diblokir,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ⑤ Centang lunas button
                    IconButton(
                      onPressed: () async {
                        final confirmed = await ConfirmDialog.show(
                          context,
                          title: 'Tandai Lunas?',
                          message:
                              'Apakah anda yakin $nama sudah melunasi pembayaran?',
                          icon: Icons.check_circle_outline,
                          confirmColor: const Color(0xFF4CAF50),
                        );
                        if (confirmed) {
                          await provider.tandaiLunas(transaksi);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$nama telah lunas! ✅'),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(
                        transaksi.status == 'lunas'
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: transaksi.status == 'lunas'
                            ? const Color(0xFF4CAF50)
                            : Colors.white.withOpacity(0.4),
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                        'Pinjam', formatRupiah(transaksi.nominalPinjaman)),
                    _buildInfoChip(
                        'Harus Bayar', formatRupiah(transaksi.totalHarusBayar)),
                    _buildInfoChip(
                      isHutang ? 'Sisa' : 'Jatuh Tempo',
                      isHutang
                          ? formatRupiah(transaksi.sisaHutang)
                          : formatTanggal(transaksi.tanggalJatuhTempo),
                    ),
                  ],
                ),
                if (isHutang && transaksi.tanggalJanjiBerikutnya != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📅 Janji bayar: ${formatTanggal(transaksi.tanggalJanjiBerikutnya!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
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

  Widget _buildInfoChip(String label, String value) {
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showTransaksiAktifModal(BuildContext context, AppProvider provider) {
    final activeList =
        provider.allTransaksi.where((t) => t.status != 'lunas').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
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

              // Header
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
                            color: const Color(0xFF42A5F5).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF42A5F5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daftar Transaksi Aktif',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${activeList.length} nasabah sedang transaksi aktif',
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

              // List of active transactions
              Expanded(
                child: activeList.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada transaksi aktif',
                          style: TextStyle(color: Colors.white.withOpacity(0.4)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: activeList.length,
                        itemBuilder: (context, index) {
                          final t = activeList[index];
                          final nama = provider.getNasabahNama(t.nasabahId);
                          final nasabah = provider.getNasabahFromList(t.nasabahId);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF42A5F5).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nasabah Header Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: const Color(0xFF42A5F5).withOpacity(0.2),
                                            child: Text(
                                              nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                color: Color(0xFF42A5F5),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nama,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (nasabah != null)
                                                  Text(
                                                    nasabah.nomorTelpon,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white.withOpacity(0.4),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status Tag
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: t.status == 'sebagian'
                                            ? const Color(0xFFFFB300).withOpacity(0.2)
                                            : const Color(0xFF42A5F5).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        t.status == 'sebagian' ? 'Bayar Sebagian' : 'Aktif',
                                        style: TextStyle(
                                          color: t.status == 'sebagian'
                                              ? const Color(0xFFFFB300)
                                              : const Color(0xFF42A5F5),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),
                                const Divider(color: Colors.white10, height: 1),
                                const SizedBox(height: 14),

                                // Details Grid
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        'Nominal Pinjaman',
                                        formatRupiah(t.nominalPinjaman),
                                        Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        'Estimasi Keuntungan',
                                        formatRupiah(t.biayaAdmin),
                                        const Color(0xFF4CAF50),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        'Total Harus Bayar',
                                        formatRupiah(t.totalHarusBayar),
                                        const Color(0xFFD4AF37),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        'Sisa Hutang',
                                        formatRupiah(t.sisaHutang),
                                        const Color(0xFFE53935),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        'Tanggal Pinjam',
                                        formatTanggal(t.tanggalPinjam),
                                        Colors.white70,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        'Jatuh Tempo',
                                        formatTanggal(t.tanggalJatuhTempo),
                                        const Color(0xFFFF7043),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Action Buttons Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BayarScreen(transaksi: t),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.payment, size: 16),
                                        label: const Text('Bayar / Detail'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF42A5F5),
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: () async {
                                        final confirmed = await ConfirmDialog.show(
                                          context,
                                          title: 'Tandai Lunas?',
                                          message: 'Apakah anda yakin $nama sudah melunasi pembayaran?',
                                          icon: Icons.check_circle_outline,
                                          confirmColor: const Color(0xFF4CAF50),
                                        );
                                        if (confirmed) {
                                          await provider.tandaiLunas(t);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                                      tooltip: 'Tandai Lunas',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
