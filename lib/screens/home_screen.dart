import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/verification_model.dart';
import '../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String _getProxyUrl(String originalUrl) {
  if (originalUrl.contains('i.ibb.co') || originalUrl.contains('ibb.co')) {
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(originalUrl)}';
  }
  return originalUrl;
}

void _showFullScreenImage(BuildContext context, String imageUrl, String tag) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      barrierDismissible: true,
      pageBuilder: (context, _, __) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: tag,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.broken_image, color: Colors.white, size: 64),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  // Filter state
  String? _statusFilter;
  String? _jenisBarangFilter;
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.elasticOut),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabAnimController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildFeedPage(),
          _buildNotificationsPage(),
          _buildProfilePage(),
          _buildHelpPage(),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => Navigator.pushNamed(context, '/create'),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Bottom Navigation ────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Beranda'),
              _buildNavItem(1, Icons.notifications_outlined, 'Notifikasi'),
              const SizedBox(width: 56), // Space for FAB
              _buildNavItem(2, Icons.person_outline_rounded, 'Profil'),
              _buildNavItem(3, Icons.help_outline_rounded, 'Bantuan'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Feed Page ────────────────────────────────────────────────
  Widget _buildFeedPage() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: AppColors.background,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                    cacheWidth: 108,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'CariUnpam',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _showFilterSheet,
              tooltip: 'Filter',
            ),
          ],
        ),

        // Active Filters
        if (_statusFilter != null || _jenisBarangFilter != null)
          SliverToBoxAdapter(
            child: _buildActiveFilters(),
          ),

        // Posts List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: _buildPostsList(),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (_statusFilter != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(_statusFilter!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _statusFilter == 'HILANG'
                          ? AppColors.hilang
                          : AppColors.ditemukan,
                    )),
                deleteIcon:
                    const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                onDeleted: () =>
                    setState(() => _statusFilter = null),
                backgroundColor: _statusFilter == 'HILANG'
                    ? AppColors.hilangBg
                    : AppColors.ditemukanBg,
                side: BorderSide.none,
              ),
            ),
          if (_jenisBarangFilter != null)
            Chip(
              label: Text(_jenisBarangFilter!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary)),
              deleteIcon:
                  const Icon(Icons.close, size: 16, color: AppColors.textMuted),
              onDeleted: () =>
                  setState(() => _jenisBarangFilter = null),
              backgroundColor: AppColors.surfaceLight,
              side: BorderSide.none,
            ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _postService.getPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded,
                      size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada postingan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap tombol + untuk membuat laporan baru',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final posts = snapshot.data!.docs;
        final filteredPosts = posts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['statusPost'] != 'AKTIF') return false;
          if (_statusFilter != null && data['statusKejadian'] != _statusFilter) return false;
          if (_jenisBarangFilter != null && data['jenisBarang'] != _jenisBarangFilter) return false;
          
          if (_searchController.text.isNotEmpty) {
            final searchTerm = _searchController.text.toLowerCase();
            final name = (data['namaBarang'] ?? '').toString().toLowerCase();
            final nim = (data['nim'] ?? '').toString().toLowerCase();
            final desc = (data['deskripsi'] ?? '').toString().toLowerCase();
            if (!name.contains(searchTerm) && !nim.contains(searchTerm) && !desc.contains(searchTerm)) {
              return false;
            }
          }
          return true;
        }).toList();

        // Sort locally to replace orderBy('createdAt', descending: true)
        filteredPosts.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // descending
        });

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = PostModel.fromFirestore(filteredPosts[index]);
              return _PostCard(
                post: post,
                onTap: () => _showPostDetail(post),
              );
            },
            childCount: filteredPosts.length,
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Filter Postingan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Status filter
                const Text('Status Kejadian',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildFilterChip(
                      'HILANG',
                      _statusFilter == 'HILANG',
                      AppColors.hilang,
                      () {
                        setSheetState(() {});
                        setState(() {
                          _statusFilter =
                              _statusFilter == 'HILANG' ? null : 'HILANG';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'DITEMUKAN',
                      _statusFilter == 'DITEMUKAN',
                      AppColors.ditemukan,
                      () {
                        setSheetState(() {});
                        setState(() {
                          _statusFilter = _statusFilter == 'DITEMUKAN'
                              ? null
                              : 'DITEMUKAN';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Jenis barang filter
                const Text('Jenis Barang',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.itemCategories.map((cat) {
                    final label = cat['label'] as String;
                    return _buildFilterChip(
                      label,
                      _jenisBarangFilter == label,
                      AppColors.primary,
                      () {
                        setSheetState(() {});
                        setState(() {
                          _jenisBarangFilter =
                              _jenisBarangFilter == label ? null : label;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Search by NIM
                TextFormField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari NIM / nama barang...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setSheetState(() {});
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) {
                    setSheetState(() {});
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),

                // Apply
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Terapkan Filter'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ─── Post Detail ──────────────────────────────────────────────
  void _showPostDetail(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status badge
              Row(
                children: [
                  _StatusBadge(status: post.statusKejadian),
                  if (post.statusPost == 'SELESAI') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.selesaiBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('SELESAI',
                          style: TextStyle(
                              color: AppColors.selesai,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    post.jenisBarang,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image
              if (post.fotoUrl != null && post.fotoUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, _getProxyUrl(post.fotoUrl!), 'post_${post.id}_main'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Hero(
                      tag: 'post_${post.id}_main',
                      child: Image.network(
                        _getProxyUrl(post.fotoUrl!),
                        height: 220,
                        width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 220,
                        width: double.infinity,
                        color: AppColors.surfaceLight,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            error.toString(),
                            style: const TextStyle(color: AppColors.error, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
              if (post.fotoUrl != null && post.fotoUrl!.isNotEmpty)
                const SizedBox(height: 20),

              // Title
              Text(
                post.namaBarang,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Info grid
              _DetailInfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Lokasi',
                  value: post.lokasi),
              _DetailInfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Waktu Kejadian',
                  value: DateFormat('dd MMM yyyy, HH:mm')
                      .format(post.waktuKejadian.toDate())),
              if (post.nim != null && post.nim!.isNotEmpty)
                _DetailInfoRow(
                    icon: Icons.badge_outlined,
                    label: 'NIM',
                    value: post.nim!),
              if (post.namaPadaKtm != null && post.namaPadaKtm!.isNotEmpty)
                _DetailInfoRow(
                    icon: Icons.person_outline,
                    label: 'Nama pada KTM',
                    value: post.namaPadaKtm!),
              if (post.warnaDominan != null && post.warnaDominan!.isNotEmpty)
                _DetailInfoRow(
                    icon: Icons.palette_outlined,
                    label: 'Warna Dominan',
                    value: post.warnaDominan!),
              if (post.namaIdentitas != null && post.namaIdentitas!.isNotEmpty)
                _DetailInfoRow(
                    icon: Icons.perm_identity,
                    label: 'Identitas',
                    value: post.namaIdentitas!),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Deskripsi / Ciri Khusus',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post.deskripsi,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reward
              if (post.rewardNominal != null && post.rewardNominal != 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.rewardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.reward.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.reward, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reward untuk Penemu',
                              style: TextStyle(
                                  color: AppColors.reward,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            post.rewardLabel ?? '-',
                            style: const TextStyle(
                              color: AppColors.reward,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Reporter info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      backgroundImage: post.userPhotoUrl.isNotEmpty
                          ? NetworkImage(post.userPhotoUrl)
                          : null,
                      child: post.userPhotoUrl.isEmpty
                          ? Text(
                              post.userName.isNotEmpty
                                  ? post.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Diposting ${_timeAgo(post.createdAt.toDate())}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _contactViaWhatsApp(post),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 22),
                  label: const Text(
                    'Hubungi Pelapor via WhatsApp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Verification Thread
              _buildVerificationThread(post),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _contactViaWhatsApp(PostModel post) async {
    // Get reporter's WhatsApp number from their user profile
    final userProfile = await _authService.getUserProfile(post.userId);
    final nomorWa = userProfile?['nomorWa'] ?? '';

    if (nomorWa.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor WhatsApp pelapor tidak tersedia'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Format number (remove leading 0, add 62)
    String formattedNumber = nomorWa;
    if (formattedNumber.startsWith('0')) {
      formattedNumber = '62${formattedNumber.substring(1)}';
    }
    if (!formattedNumber.startsWith('62')) {
      formattedNumber = '62$formattedNumber';
    }

    final message = Uri.encodeComponent(
      'Halo, saya dari aplikasi CariUnpam.\n'
      'Saya ingin menanyakan tentang barang "${post.namaBarang}" '
      'yang Anda ${post.statusKejadian == "HILANG" ? "laporkan hilang" : "temukan"}.\n'
      'Lokasi: ${post.lokasi}\n'
      'Terima kasih! 🙏',
    );

    final url = Uri.parse('https://wa.me/$formattedNumber?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // --- Verification Thread ---
  Widget _buildVerificationThread(PostModel post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thread Verifikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gunakan fitur ini untuk mengirim foto bukti jika Anda adalah penemu atau pemilik barang.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .doc(post.id)
              .collection('verifications')
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Terjadi kesalahan memuat verifikasi.', style: TextStyle(color: AppColors.error));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final docs = snapshot.data?.docs ?? [];
            return Column(
              children: [
                if (docs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Belum ada verifikasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ...docs.map((doc) {
                  final v = VerificationModel.fromFirestore(doc);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              backgroundImage: v.userPhotoUrl.isNotEmpty ? NetworkImage(v.userPhotoUrl) : null,
                              child: v.userPhotoUrl.isEmpty ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.userName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  Text(_timeAgo(v.createdAt.toDate()), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            if (v.userId == FirebaseAuth.instance.currentUser?.uid)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () {
                                  _postService.deleteVerification(post.id, v.id);
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(v.teks, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        if (v.fotoUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => _showFullScreenImage(context, _getProxyUrl(v.fotoUrl), 'verify_${v.id}'),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Hero(
                                tag: 'verify_${v.id}',
                                child: Image.network(
                                  _getProxyUrl(v.fotoUrl),
                                  height: 150,
                                  width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (c, child, progress) => progress == null ? child : Container(height: 150, color: AppColors.surfaceLight, child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),
                              errorBuilder: (c, e, s) => Container(height: 150, color: AppColors.surfaceLight, child: const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted))),
                            ),
                          ),
                        ),
                      ),
                        ]
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddVerificationForm(post.id),
                    icon: const Icon(Icons.add_a_photo_rounded),
                    label: const Text('Beri Verifikasi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAddVerificationForm(String postId) {
    final _teksController = TextEditingController();
    File? _selectedImage;
    bool _isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Beri Verifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _teksController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tulis keterangan...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                      if (pickedFile != null) {
                        setStateSB(() => _selectedImage = File(pickedFile.path));
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                      ),
                      child: _selectedImage == null
                          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add_photo_alternate, color: AppColors.primary, size: 32), SizedBox(height: 8), Text('Pilih Foto Bukti (Wajib)', style: TextStyle(color: AppColors.primary))]))
                          : const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (_teksController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keterangan tidak boleh kosong')));
                          return;
                        }
                        if (_selectedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto bukti wajib dilampirkan')));
                          return;
                        }

                        setStateSB(() => _isLoading = true);
                        try {
                          final fotoUrl = await _postService.uploadImage(_selectedImage!);
                          if (fotoUrl != null) {
                            await _postService.addVerification(postId, {
                              'teks': _teksController.text.trim(),
                              'fotoUrl': fotoUrl,
                            });
                          }
                          if (mounted) Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim verifikasi: $e')));
                        } finally {
                          if (mounted) setStateSB(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kirim Verifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // ─── Notifications Page ──────────────────────────────────────
  Widget _buildNotificationsPage() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title: Text('Notifikasi',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: StreamBuilder<QuerySnapshot>(
            stream: _postService.getNotificationsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text('Belum ada notifikasi',
                            style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isRead = data['read'] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isRead
                            ? AppColors.surface
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isRead
                              ? AppColors.divider
                              : AppColors.primary.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isRead
                                ? AppColors.surfaceLight
                                : AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: isRead
                                ? AppColors.textMuted
                                : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          data['message'] ?? '',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight:
                                isRead ? FontWeight.w400 : FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                        trailing: !isRead
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                        onTap: () {
                          if (!isRead) {
                            _postService.markNotificationRead(doc.id);
                          }
                        },
                      ),
                    );
                  },
                  childCount: snapshot.data!.docs.length,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Profile Page ─────────────────────────────────────────────
  Widget _buildProfilePage() {
    final user = _authService.currentUser;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.background,
          title:
              const Text('Profil', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.error),
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              tooltip: 'Keluar',
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile header
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          (user?.displayName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Pengguna',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),

                // My Posts header
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Postingan Saya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // My Posts List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: StreamBuilder<QuerySnapshot>(
            stream: _postService.getMyPostsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.post_add_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text('Belum ada postingan',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post =
                        PostModel.fromFirestore(snapshot.data!.docs[index]);
                    return _MyPostCard(
                      post: post,
                      onMarkDone: () {
                        _postService.updatePostStatus(post.id, 'SELESAI');
                      },
                      onDelete: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Postingan?'),
                            content: const Text(
                                'Postingan ini akan dihapus secara permanen.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _postService.deletePost(post.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('Hapus',
                                    style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  childCount: snapshot.data!.docs.length,
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes} menit lalu';
    return 'Baru saja';
  }

  // ─── Help / Bantuan Page ──────────────────────────────────────
  Widget _buildHelpPage() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: AppColors.background,
          title: const Text(
            'Pusat Bantuan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.help_center_rounded, size: 64, color: AppColors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Ada yang bisa kami bantu?',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Temukan jawaban dari pertanyaan yang sering diajukan di bawah ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'FAQ (Tanya Jawab)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildFaqItem(
                  'Bagaimana cara melaporkan barang hilang?',
                  'Tap tombol + (tambah) di tengah bawah layar, lalu pilih opsi HILANG. Isi detail barang selengkap mungkin agar mudah dikenali.'
                ),
                _buildFaqItem(
                  'Bagaimana jika barang saya sudah ketemu?',
                  'Buka tab Profil, cari postingan barang Anda, tap ikon titik tiga di pojok kanan atas, lalu pilih "Tandai Selesai".'
                ),
                _buildFaqItem(
                  'Apakah saya bisa menghubungi penemu barang?',
                  'Ya! Tap pada postingan barang yang ditemukan, lalu tekan tombol "Hubungi via WhatsApp" di bagian bawah untuk langsung mengobrol dengan penemunya.'
                ),
                _buildFaqItem(
                  'Apakah aplikasi ini resmi dari kampus?',
                  'Aplikasi ini adalah wadah independen mahasiswa Universitas Pamulang untuk saling membantu mengembalikan barang yang hilang atau tertinggal di area kampus.'
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Hubungi Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.email_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Punya pertanyaan lebih lanjut?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'isnandarario49@gmail.com',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // padding for bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        collapsedIconColor: AppColors.primary,
        iconColor: AppColors.primary,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Post Card Widget ─────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _PostCard({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (post.fotoUrl != null && post.fotoUrl!.isNotEmpty)
              GestureDetector(
                onTap: () => _showFullScreenImage(context, _getProxyUrl(post.fotoUrl!), 'card_${post.id}'),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Hero(
                    tag: 'card_${post.id}',
                    child: Image.network(
                      _getProxyUrl(post.fotoUrl!),
                      height: 180,
                      width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  },
                  errorBuilder: (_, __, _) => Container(
                    height: 180,
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          color: AppColors.textMuted, size: 40),
                    ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges row
                  Row(
                    children: [
                      _StatusBadge(status: post.statusKejadian),
                      if (post.rewardNominal != null &&
                          post.rewardNominal != 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.rewardBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events_rounded,
                                  size: 12, color: AppColors.reward),
                              const SizedBox(width: 4),
                              Text(
                                'REWARD',
                                style: const TextStyle(
                                  color: AppColors.reward,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (post.statusPost == 'SELESAI') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.selesaiBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('SELESAI',
                              style: TextStyle(
                                  color: AppColors.selesai,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.jenisBarang,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    post.namaBarang,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    post.deskripsi,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Location and time row
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.lokasi,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(post.createdAt.toDate()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Author row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        backgroundImage: post.userPhotoUrl.isNotEmpty
                            ? NetworkImage(post.userPhotoUrl)
                            : null,
                        child: post.userPhotoUrl.isEmpty
                            ? Text(
                                post.userName.isNotEmpty
                                    ? post.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.userName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}h lalu';
    if (diff.inHours > 0) return '${diff.inHours}j lalu';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m lalu';
    return 'Baru saja';
  }
}

// ─── Status Badge ─────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isHilang = status == 'HILANG';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHilang ? AppColors.hilangBg : AppColors.ditemukanBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHilang ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 12,
            color: isHilang ? AppColors.hilang : AppColors.ditemukan,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: isHilang ? AppColors.hilang : AppColors.ditemukan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Info Row ──────────────────────────────────────────────
class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── My Post Card (for Profile page) ─────────────────────────────
class _MyPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onMarkDone;
  final VoidCallback onDelete;

  const _MyPostCard({
    required this.post,
    required this.onMarkDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: post.statusKejadian == 'HILANG'
                ? AppColors.hilangBg
                : AppColors.ditemukanBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            post.statusKejadian == 'HILANG'
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline,
            color: post.statusKejadian == 'HILANG'
                ? AppColors.hilang
                : AppColors.ditemukan,
            size: 24,
          ),
        ),
        title: Text(
          post.namaBarang,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            _StatusBadge(status: post.statusKejadian),
            if (post.statusPost == 'SELESAI') ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.selesaiBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('SELESAI',
                    style: TextStyle(
                        color: AppColors.selesai,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          color: AppColors.surface,
          onSelected: (value) {
            if (value == 'done') onMarkDone();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (post.statusPost != 'SELESAI')
              const PopupMenuItem(
                value: 'done',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Tandai Selesai',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('Hapus',
                      style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
