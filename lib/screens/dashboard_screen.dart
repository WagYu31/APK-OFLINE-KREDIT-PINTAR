import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/transaksi.dart';
import '../widgets/stat_card.dart';
import '../widgets/card_badge.dart';
import '../widgets/confirm_dialog.dart';
import 'bayar_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                _buildStatsGrid(stats),
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
                else
                  ...jatuhTempo.map((t) => _buildTransaksiCard(
                        context, t, provider,
                        isJatuhTempo: true)),
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
                else
                  ...hutang.map((t) => _buildTransaksiCard(
                        context, t, provider,
                        isHutang: true)),
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

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: [
        StatCard(
          title: 'Total Pinjaman',
          value: formatRupiah((stats['totalPinjaman'] ?? 0.0) as double),
          icon: Icons.account_balance_wallet,
          color: Colors.white,
        ),
        StatCard(
          title: 'Total Pengembalian',
          value: formatRupiah((stats['totalPengembalian'] ?? 0.0) as double),
          icon: Icons.payments_outlined,
          color: const Color(0xFF66BB6A),
        ),
        StatCard(
          title: 'Total Nasabah',
          value: '${stats['totalNasabah'] ?? 0}',
          icon: Icons.people_outline,
          color: const Color(0xFFAB47BC),
        ),
        StatCard(
          title: 'Transaksi Aktif',
          value: '${stats['totalTransaksiAktif'] ?? 0}',
          icon: Icons.receipt_long,
          color: const Color(0xFF42A5F5),
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
}
