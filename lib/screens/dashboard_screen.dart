import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/nasabah.dart';
import '../models/transaksi.dart';
import '../widgets/stat_card.dart';
import '../widgets/card_badge.dart';
import '../widgets/confirm_dialog.dart';
import 'bayar_screen.dart';

class GroupedNasabahTransaksi {
  final int nasabahId;
  final Nasabah? nasabah;
  final List<Transaksi> transaksiList;

  GroupedNasabahTransaksi({
    required this.nasabahId,
    this.nasabah,
    required this.transaksiList,
  });

  double get totalNominalPinjaman =>
      transaksiList.fold(0.0, (sum, t) => sum + t.nominalPinjaman);

  double get totalBiayaAdmin =>
      transaksiList.fold(0.0, (sum, t) => sum + t.biayaAdmin);

  double get totalHarusBayar =>
      transaksiList.fold(0.0, (sum, t) => sum + t.totalHarusBayar);

  double get totalSisaHutang =>
      transaksiList.fold(0.0, (sum, t) => sum + t.sisaHutang);

  String get earliestTanggalPinjam {
    if (transaksiList.isEmpty) return '';
    final sorted = List<Transaksi>.from(transaksiList)
      ..sort((a, b) => a.tanggalPinjam.compareTo(b.tanggalPinjam));
    return sorted.first.tanggalPinjam;
  }

  String get earliestJatuhTempo {
    if (transaksiList.isEmpty) return '';
    final sorted = List<Transaksi>.from(transaksiList)
      ..sort((a, b) => a.tanggalJatuhTempo.compareTo(b.tanggalJatuhTempo));
    return sorted.first.tanggalJatuhTempo;
  }
}

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

  List<GroupedNasabahTransaksi> _groupTransaksiByNasabah(
      List<Transaksi> rawList, AppProvider provider) {
    final Set<int> nasabahIds = rawList.map((t) => t.nasabahId).toSet();

    final List<GroupedNasabahTransaksi> result = [];
    for (var nasabahId in nasabahIds) {
      final nasabah = provider.getNasabahFromList(nasabahId);
      // Fetch ALL active (unpaid) transactions for this nasabah from provider.allTransaksi
      final allActiveForNasabah = provider.allTransaksi
          .where((t) => t.nasabahId == nasabahId && t.status != 'lunas')
          .toList();

      final txList = allActiveForNasabah.isNotEmpty
          ? allActiveForNasabah
          : rawList.where((t) => t.nasabahId == nasabahId).toList();

      result.add(GroupedNasabahTransaksi(
        nasabahId: nasabahId,
        nasabah: nasabah,
        transaksiList: txList,
      ));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.statistik;
        final rawJatuhTempo = provider.transaksiJatuhTempo;
        final rawHutang = provider.transaksiHutang;

        final groupedJatuhTempo =
            _groupTransaksiByNasabah(rawJatuhTempo, provider);
        final groupedHutang = _groupTransaksiByNasabah(rawHutang, provider);

        final displayedJatuhTempo = _showAllJatuhTempo
            ? groupedJatuhTempo
            : groupedJatuhTempo.take(3).toList();

        final displayedHutang = _showAllHutang
            ? groupedHutang
            : groupedHutang.take(3).toList();

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
                  '${groupedJatuhTempo.length} nasabah',
                  const Color(0xFFFFB300),
                ),
                const SizedBox(height: 12),
                if (groupedJatuhTempo.isEmpty)
                  _buildEmptyState(
                    'Tidak ada nasabah jatuh tempo',
                    Icons.check_circle_outline,
                    const Color(0xFF4CAF50),
                  )
                else ...[
                  ...displayedJatuhTempo.map((item) =>
                      _buildGroupedTransaksiCard(context, item, provider,
                          isJatuhTempo: true)),
                  if (groupedJatuhTempo.length > 3) ...[
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
                                  : 'Lihat Semua (${groupedJatuhTempo.length} Nasabah)',
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
                  '${groupedHutang.length} nasabah',
                  const Color(0xFFE53935),
                ),
                const SizedBox(height: 12),
                if (groupedHutang.isEmpty)
                  _buildEmptyState(
                    'Tidak ada nasabah punya hutang',
                    Icons.sentiment_satisfied_alt,
                    const Color(0xFF4CAF50),
                  )
                else ...[
                  ...displayedHutang.map((item) =>
                      _buildGroupedTransaksiCard(context, item, provider,
                          isHutang: true)),
                  if (groupedHutang.length > 3) ...[
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
                                  : 'Lihat Semua (${groupedHutang.length} Nasabah)',
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

  Widget _buildGroupedTransaksiCard(
    BuildContext context,
    GroupedNasabahTransaksi item,
    AppProvider provider, {
    bool isJatuhTempo = false,
    bool isHutang = false,
  }) {
    final nama = item.nasabah?.nama ?? provider.getNasabahNama(item.nasabahId);
    final nasabah = item.nasabah;
    final cardColor =
        isHutang ? const Color(0xFFE53935) : const Color(0xFFFFB300);
    final count = item.transaksiList.length;

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
            if (count == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BayarScreen(transaksi: item.transaksiList.first),
                ),
              );
            } else {
              _showSubTransaksiModal(context, provider, item, cardColor);
            }
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
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        nama,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (count > 1) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF42A5F5).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF42A5F5).withOpacity(0.4),
                                          ),
                                        ),
                                        child: Text(
                                          '$count Pinjaman',
                                          style: const TextStyle(
                                            color: Color(0xFF42A5F5),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (nasabah != null) ...[
                                  const SizedBox(height: 2),
                                  CardBadge(
                                    isKuning: nasabah.kartuKuning,
                                    isMerah: nasabah.kartuMerah,
                                    isDiblokir: nasabah.diblokir,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (count == 1)
                      IconButton(
                        onPressed: () async {
                          final t = item.transaksiList.first;
                          final confirmed = await ConfirmDialog.show(
                            context,
                            title: 'Tandai Lunas?',
                            message:
                                'Apakah anda yakin $nama sudah melunasi pembayaran?',
                            icon: Icons.check_circle_outline,
                            confirmColor: const Color(0xFF4CAF50),
                          );
                          if (confirmed) {
                            await provider.tandaiLunas(t);
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
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white38,
                          size: 26,
                        ),
                      )
                    else
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white38,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                        count > 1 ? 'Total Pinjam' : 'Pinjam',
                        formatRupiah(item.totalNominalPinjaman)),
                    _buildInfoChip(
                        count > 1 ? 'Total Bayar' : 'Harus Bayar',
                        formatRupiah(item.totalHarusBayar)),
                    _buildInfoChip(
                      isHutang || item.totalSisaHutang < item.totalHarusBayar
                          ? (count > 1 ? 'Total Sisa' : 'Sisa Hutang')
                          : 'Jatuh Tempo',
                      isHutang || item.totalSisaHutang < item.totalHarusBayar
                          ? formatRupiah(item.totalSisaHutang)
                          : formatTanggal(item.earliestJatuhTempo),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubTransaksiModal(
    BuildContext context,
    AppProvider provider,
    GroupedNasabahTransaksi item,
    Color themeColor,
  ) {
    final nama = item.nasabah?.nama ?? provider.getNasabahNama(item.nasabahId);

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: themeColor.withOpacity(0.2),
                          child: Text(
                            nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Daftar ${item.transaksiList.length} pinjaman aktif',
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
              if (item.transaksiList.length > 1) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BayarScreen(
                              transaksi: item.transaksiList.first,
                              isGabungan: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payments, size: 20),
                      label: Text(
                        '💳 Bayar Gabungan Sekaligus (${formatRupiah(item.totalSisaHutang)})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: item.transaksiList.length,
                  itemBuilder: (context, index) {
                    final t = item.transaksiList[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeColor.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pinjaman #${index + 1}',
                                style: TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: t.status == 'sebagian'
                                      ? const Color(0xFFFFB300).withOpacity(0.2)
                                      : const Color(0xFF42A5F5).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t.status == 'sebagian'
                                      ? 'Bayar Sebagian'
                                      : 'Aktif',
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
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoChip('Pinjam', formatRupiah(t.nominalPinjaman)),
                              _buildInfoChip('Harus Bayar', formatRupiah(t.totalHarusBayar)),
                              _buildInfoChip('Jatuh Tempo', formatTanggal(t.tanggalJatuhTempo)),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                                  label: const Text('Bayar / Detail Pinjaman Ini'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () async {
                                  final confirmed = await ConfirmDialog.show(
                                    context,
                                    title: 'Tandai Lunas?',
                                    message:
                                        'Apakah anda yakin pinjaman #${index + 1} $nama sudah melunasi pembayaran?',
                                    icon: Icons.check_circle_outline,
                                    confirmColor: const Color(0xFF4CAF50),
                                  );
                                  if (confirmed) {
                                    await provider.tandaiLunas(t);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  }
                                },
                                icon: const Icon(Icons.check_circle,
                                    color: Color(0xFF4CAF50), size: 26),
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
    final groupedActiveList = _groupTransaksiByNasabah(activeList, provider);

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
                              '${groupedActiveList.length} nasabah sedang transaksi aktif',
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

              // List of active transactions grouped by nasabah
              Expanded(
                child: groupedActiveList.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada transaksi aktif',
                          style: TextStyle(color: Colors.white.withOpacity(0.4)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: groupedActiveList.length,
                        itemBuilder: (context, index) {
                          final item = groupedActiveList[index];
                          final nama = provider.getNasabahNama(item.nasabahId);
                          final nasabah = provider.getNasabahFromList(item.nasabahId);
                          final count = item.transaksiList.length;

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
                                                Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        nama,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (count > 1) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF42A5F5).withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: const Color(0xFF42A5F5).withOpacity(0.4),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '$count Pinjaman',
                                                          style: const TextStyle(
                                                            color: Color(0xFF42A5F5),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
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
                                        color: const Color(0xFF42A5F5).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        count > 1 ? '$count Pinjaman' : 'Aktif',
                                        style: const TextStyle(
                                          color: Color(0xFF42A5F5),
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
                                        count > 1 ? 'Total Pinjaman' : 'Nominal Pinjaman',
                                        formatRupiah(item.totalNominalPinjaman),
                                        Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        count > 1 ? 'Total Keuntungan' : 'Estimasi Keuntungan',
                                        formatRupiah(item.totalBiayaAdmin),
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
                                        count > 1 ? 'Total Harus Bayar' : 'Total Harus Bayar',
                                        formatRupiah(item.totalHarusBayar),
                                        const Color(0xFFD4AF37),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        count > 1 ? 'Total Sisa Hutang' : 'Sisa Hutang',
                                        formatRupiah(item.totalSisaHutang),
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
                                        formatTanggal(item.earliestTanggalPinjam),
                                        Colors.white70,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildModalDetailItem(
                                        'Jatuh Tempo',
                                        formatTanggal(item.earliestJatuhTempo),
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
                                          if (count == 1) {
                                            Navigator.pop(ctx);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BayarScreen(transaksi: item.transaksiList.first),
                                              ),
                                            );
                                          } else {
                                            _showSubTransaksiModal(context, provider, item, const Color(0xFF42A5F5));
                                          }
                                        },
                                        icon: const Icon(Icons.payment, size: 16),
                                        label: Text(count > 1 ? 'Pilih / Detail' : 'Bayar / Detail'),
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
                                        if (count == 1) {
                                          final t = item.transaksiList.first;
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
                                        } else {
                                          final confirmed = await ConfirmDialog.show(
                                            context,
                                            title: 'Pelunasan Semua Pinjaman?',
                                            message: 'Apakah anda yakin $nama sudah melunasi seluruh ($count) pembayaran pinjaman?',
                                            icon: Icons.check_circle_outline,
                                            confirmColor: const Color(0xFF4CAF50),
                                          );
                                          if (confirmed) {
                                            for (var t in item.transaksiList) {
                                              await provider.tandaiLunas(t);
                                            }
                                            if (ctx.mounted) Navigator.pop(ctx);
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
                                      tooltip: 'Tandai Lunas Semua',
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
