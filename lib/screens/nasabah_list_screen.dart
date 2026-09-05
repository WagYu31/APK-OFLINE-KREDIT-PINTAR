import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/nasabah.dart';
import '../widgets/card_badge.dart';
import '../widgets/confirm_dialog.dart';
import 'nasabah_detail_screen.dart';

class NasabahListScreen extends StatefulWidget {
  const NasabahListScreen({super.key});

  @override
  State<NasabahListScreen> createState() => _NasabahListScreenState();
}

class _NasabahListScreenState extends State<NasabahListScreen> {
  final _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectAll(List<Nasabah> list) {
    setState(() {
      if (_selectedIds.length == list.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var n in list) {
          if (n.id != null) _selectedIds.add(n.id!);
        }
      }
    });
  }

  Future<void> _deleteSelectedNasabah(AppProvider provider) async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Hapus $count Nasabah?',
      message:
          'Profil dan SELURUH data transaksi dari $count nasabah yang dipilih akan dihapus permanen!\n\nAksi ini tidak bisa dibatalkan.',
      icon: Icons.delete_forever,
      confirmColor: const Color(0xFFE53935),
    );

    if (!confirmed) return;

    await provider.deleteMultipleNasabah(_selectedIds.toList());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count nasabah berhasil dihapus! ✅'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _exitSelectionMode();
    }
  }

  Future<void> _deleteAllNasabah(AppProvider provider, List<Nasabah> list) async {
    if (list.isEmpty) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Hapus SEMUA Nasabah?',
      message:
          'SEMUA ${list.length} nasabah beserta seluruh riwayat transaksinya akan dihapus secara permanen!',
      icon: Icons.delete_forever,
      confirmColor: const Color(0xFFE53935),
    );

    if (!confirmed) return;

    final allIds = list.map((n) => n.id!).whereType<int>().toList();
    await provider.deleteMultipleNasabah(allIds);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Semua nasabah berhasil dihapus! ✅'),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _exitSelectionMode();
    }
  }

  void _showLongPressMenu(
      BuildContext context, Nasabah nasabah, AppProvider provider, List<Nasabah> allList) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header Nasabah Info
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: nasabah.diblokir
                            ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                            : [const Color(0xFFD4AF37), const Color(0xFFB8860B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        nasabah.nama.isNotEmpty
                            ? nasabah.nama[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nasabah.nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nasabah.nomorTelpon,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),

              // Option 1: Hapus Nasabah Ini
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                title: Text(
                  'Hapus ${nasabah.nama} & Transaksinya',
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Hapus ${nasabah.nama}?',
                    message:
                        'Profil ${nasabah.nama} dan seluruh riwayat transaksinya akan dihapus secara permanen!',
                    icon: Icons.delete_forever,
                    confirmColor: const Color(0xFFE53935),
                  );
                  if (confirmed && nasabah.id != null) {
                    await provider.deleteNasabah(nasabah.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nasabah ${nasabah.nama} berhasil dihapus! ✅'),
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
              ),

              // Option 2: Pilih Banyak (Ceklis Satu-Satu)
              ListTile(
                leading: const Icon(Icons.checklist_rounded, color: Color(0xFFD4AF37)),
                title: const Text(
                  'Pilih Banyak (Ceklis Satu-Satu)',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isSelectionMode = true;
                    if (nasabah.id != null) {
                      _selectedIds.add(nasabah.id!);
                    }
                  });
                },
              ),

              // Option 3: Hapus Semua Nasabah
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Color(0xFFFF5252)),
                title: const Text(
                  'Hapus Semua Nasabah',
                  style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAllNasabah(provider, allList);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final nasabahList = provider.allNasabah;
        final isAllSelected = nasabahList.isNotEmpty &&
            _selectedIds.length == nasabahList.length;

        return Column(
          children: [
            // Search Bar & Selection Top Bar
            if (_isSelectionMode)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: _exitSelectionMode,
                    ),
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} terpilih',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _toggleSelectAll(nasabahList),
                      icon: Icon(
                        isAllSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: const Color(0xFFD4AF37),
                        size: 20,
                      ),
                      label: Text(
                        isAllSelected ? 'Batal Semua' : 'Pilih Semua',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => provider.setSearchQuery(v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '🔍 Cari nama, nomor HP...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white.withOpacity(0.4)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close,
                                color: Colors.white.withOpacity(0.4)),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            // Header Row: Count & Delete Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isSelectionMode ? '☑️ Mode Pilih Hapus' : '👥 Semua Nasabah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Row(
                    children: [
                      if (_isSelectionMode) ...[
                        if (_selectedIds.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _deleteSelectedNasabah(provider),
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: Text('Hapus (${_selectedIds.length})'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${nasabahList.length} orang',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_sweep,
                              color: Color(0xFFE53935), size: 22),
                          tooltip: 'Mode Hapus Nasabah',
                          onPressed: () {
                            setState(() {
                              _isSelectionMode = true;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Nasabah List
            Expanded(
              child: nasabahList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty
                                ? 'Tidak ditemukan'
                                : 'Belum ada nasabah',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: nasabahList.length,
                      itemBuilder: (context, index) {
                        final nasabah = nasabahList[index];
                        final isSelected =
                            _selectedIds.contains(nasabah.id);

                        return _buildNasabahCard(
                          context,
                          nasabah,
                          provider,
                          nasabahList,
                          isSelected: isSelected,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNasabahCard(
    BuildContext context,
    Nasabah nasabah,
    AppProvider provider,
    List<Nasabah> allList, {
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE53935).withOpacity(0.12)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFE53935)
              : nasabah.diblokir
                  ? const Color(0xFFE53935).withOpacity(0.3)
                  : nasabah.kartuKuning
                      ? const Color(0xFFFFB300).withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (nasabah.id != null) {
                  if (isSelected) {
                    _selectedIds.remove(nasabah.id);
                  } else {
                    _selectedIds.add(nasabah.id!);
                  }
                }
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NasabahDetailScreen(nasabah: nasabah),
                ),
              );
            }
          },
          onLongPress: () {
            _showLongPressMenu(context, nasabah, provider, allList);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection Checkbox
                if (_isSelectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (nasabah.id != null) {
                          if (val == true) {
                            _selectedIds.add(nasabah.id!);
                          } else {
                            _selectedIds.remove(nasabah.id);
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                ],

                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: nasabah.diblokir
                          ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                          : [const Color(0xFFD4AF37), const Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      nasabah.nama.isNotEmpty
                          ? nasabah.nama[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nasabah.nama,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: nasabah.diblokir
                              ? const Color(0xFFEF4444)
                              : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            nasabah.nomorTelpon,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.55),
                            ),
                          ),
                          CardBadge(
                            isKuning: nasabah.kartuKuning,
                            isMerah: nasabah.kartuMerah,
                            isDiblokir: nasabah.diblokir,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isSelectionMode
                      ? (isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked)
                      : Icons.chevron_right,
                  color: isSelected
                      ? const Color(0xFFE53935)
                      : Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
