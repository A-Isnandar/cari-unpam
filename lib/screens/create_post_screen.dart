import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final PostService _postService = PostService();
  final ImagePicker _picker = ImagePicker();

  // Step 1: Status
  String? _statusKejadian;

  // Step 2: Category
  String? _jenisBarang;

  // Step 3: Dynamic fields
  final _nimController = TextEditingController();
  final _namaKtmController = TextEditingController();
  final _warnaController = TextEditingController();
  final _namaIdentitasController = TextEditingController();
  final _namaBarangLainnyaController = TextEditingController();

  // Step 4: Common fields
  final _namaBarangController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  DateTime _waktuKejadian = DateTime.now();

  // Photo
  File? _selectedImage;

  // Step 5: Reward
  int? _rewardNominal;
  String? _rewardLabel;
  final _manualRewardController = TextEditingController();

  // Duration
  int _durasiHari = 7;

  // State
  bool _isLoading = false;

  @override
  void dispose() {
    _nimController.dispose();
    _namaKtmController.dispose();
    _warnaController.dispose();
    _namaIdentitasController.dispose();
    _namaBarangLainnyaController.dispose();
    _namaBarangController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _manualRewardController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _waktuKejadian,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_waktuKejadian),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        ),
      );
      if (time != null && mounted) {
        setState(() {
          _waktuKejadian = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    if (_statusKejadian == null) {
      _showError('Pilih status kejadian terlebih dahulu');
      return;
    }
    if (_jenisBarang == null) {
      _showError('Pilih jenis barang terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? fotoUrl;
      if (_selectedImage != null) {
        fotoUrl = await _postService.uploadImage(_selectedImage!);
      }

      // Build the reward label
      String? rewardLbl = _rewardLabel;
      if (_rewardNominal == -1) {
        // Manual input
        final amount = int.tryParse(_manualRewardController.text) ?? 0;
        _rewardNominal = amount;
        rewardLbl = 'Rp${NumberFormat('#,###').format(amount)}';
      }

      final postData = {
        'statusKejadian': _statusKejadian,
        'jenisBarang': _jenisBarang,
        'nim': _nimController.text.trim(),
        'namaPadaKtm': _namaKtmController.text.trim(),
        'warnaDominan': _warnaController.text.trim(),
        'namaIdentitas': _namaIdentitasController.text.trim(),
        'namaBarangLainnya': _namaBarangLainnyaController.text.trim(),
        'namaBarang': _namaBarangController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'lokasi': _lokasiController.text.trim(),
        'waktuKejadian': Timestamp.fromDate(_waktuKejadian),
        'fotoUrl': fotoUrl,
        'rewardNominal': _statusKejadian == 'HILANG' ? _rewardNominal : null,
        'rewardLabel': _statusKejadian == 'HILANG' ? rewardLbl : null,
        'durasiHari': _durasiHari,
      };

      await _postService.createPost(postData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil dibuat! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Gagal membuat laporan: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 24),

              // Step 1: Status Kejadian
              _buildSectionHeader(
                  '1', 'Status Kejadian', Icons.flag_rounded),
              const SizedBox(height: 12),
              _buildStatusSelection(),
              const SizedBox(height: 28),

              // Step 2: Jenis Barang
              _buildSectionHeader(
                  '2', 'Jenis Barang', Icons.category_rounded),
              const SizedBox(height: 12),
              _buildCategorySelection(),
              const SizedBox(height: 28),

              // Step 3: Dynamic Form
              if (_jenisBarang != null) ...[
                _buildSectionHeader(
                    '3', 'Detail Barang', Icons.description_rounded),
                const SizedBox(height: 12),
                _buildDynamicForm(),
                const SizedBox(height: 28),
              ],

              // Step 4: Common fields
              _buildSectionHeader(
                  '4', 'Informasi Umum', Icons.info_outline_rounded),
              const SizedBox(height: 12),
              _buildCommonFields(),
              const SizedBox(height: 28),

              // Step 5: Optional (Reward & Duration)
              _buildSectionHeader(
                  '5', 'Opsi Tambahan', Icons.settings_rounded),
              const SizedBox(height: 12),
              _buildOptionalFields(),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Kirim Laporan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Progress Indicator ──────────────────────────────────────
  Widget _buildProgressIndicator() {
    int filled = 0;
    if (_statusKejadian != null) filled++;
    if (_jenisBarang != null) filled++;
    if (_namaBarangController.text.isNotEmpty) filled++;
    if (_selectedImage != null || _deskripsiController.text.isNotEmpty) filled++;
    filled++; // Duration always has a default

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Pengisian',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(filled / 5 * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: filled / 5,
            backgroundColor: AppColors.surfaceLight,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ─── Section Header ──────────────────────────────────────────
  Widget _buildSectionHeader(String number, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── Step 1: Status Selection ─────────────────────────────────
  Widget _buildStatusSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectionCard(
            icon: Icons.error_outline_rounded,
            label: 'HILANG',
            sublabel: 'Saya kehilangan barang',
            color: AppColors.hilang,
            selected: _statusKejadian == 'HILANG',
            onTap: () => setState(() => _statusKejadian = 'HILANG'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSelectionCard(
            icon: Icons.check_circle_outline,
            label: 'DITEMUKAN',
            sublabel: 'Saya menemukan barang',
            color: AppColors.ditemukan,
            selected: _statusKejadian == 'DITEMUKAN',
            onTap: () => setState(() => _statusKejadian = 'DITEMUKAN'),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.divider,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Category Selection ──────────────────────────────
  Widget _buildCategorySelection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.itemCategories.map((cat) {
        final label = cat['label'] as String;
        final icon = cat['icon'] as IconData;
        final selected = _jenisBarang == label;
        return GestureDetector(
          onTap: () => setState(() => _jenisBarang = label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 60) / 3,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Step 3: Dynamic Form ────────────────────────────────────
  Widget _buildDynamicForm() {
    final widgets = <Widget>[];

    // Privacy warning for DITEMUKAN with identity cards
    if (_statusKejadian == 'DITEMUKAN' && _jenisBarang == 'KTM') {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.rewardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.reward.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.privacy_tip_rounded,
                  color: AppColors.reward, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '⚠️ Demi privasi, sensor sebagian NIM dan foto wajah pada gambar sebelum diunggah.',
                  style: TextStyle(
                    color: AppColors.reward,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (_jenisBarang) {
      case 'KTM':
        widgets.addAll([
          _buildTextField(_nimController, 'NIM', Icons.badge_outlined,
              hint: 'Masukkan NIM'),
          const SizedBox(height: 14),
          _buildTextField(
              _namaKtmController, 'Nama pada KTM', Icons.person_outline,
              hint: 'Masukkan nama pada KTM'),
        ]);
        break;
      case 'Dompet':
      case 'Tas':
        widgets.addAll([
          _buildTextField(
              _warnaController, 'Warna Dominan', Icons.palette_outlined,
              hint: 'Contoh: Hitam, Coklat'),
          const SizedBox(height: 14),
          _buildTextField(_namaIdentitasController,
              'Nama Identitas di Dalamnya (Opsional)', Icons.perm_identity,
              hint: 'Jika ada kartu identitas di dalamnya',
              required: false),
        ]);
        break;
      case 'Helm':
      case 'Buku':
        widgets.add(
          _buildTextField(
              _warnaController, 'Warna Dominan', Icons.palette_outlined,
              hint: 'Contoh: Hitam, Putih'),
        );
        break;
      case 'Lainnya':
        widgets.addAll([
          _buildTextField(_namaBarangLainnyaController, 'Nama Barang',
              Icons.edit_outlined,
              hint: 'Tulis nama barangmu'),
          const SizedBox(height: 14),
          _buildTextField(
              _warnaController, 'Warna Dominan', Icons.palette_outlined,
              hint: 'Warna utama barang'),
        ]);
        break;
    }

    return Column(children: widgets);
  }

  // ─── Step 4: Common Fields ───────────────────────────────────
  Widget _buildCommonFields() {
    return Column(
      children: [
        _buildTextField(
            _namaBarangController, 'Nama Barang', Icons.inventory_2_outlined,
            hint: 'Contoh: KTM atas nama Budi',
            validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Nama barang wajib diisi';
          return null;
        }),
        const SizedBox(height: 14),

        _buildTextField(_deskripsiController, 'Deskripsi / Ciri Khusus',
            Icons.notes_rounded,
            hint: 'Jelaskan ciri-ciri barang...',
            maxLines: 3, validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Deskripsi wajib diisi';
          return null;
        }),
        const SizedBox(height: 14),

        _buildTextField(
            _lokasiController, 'Titik Lokasi Kejadian', Icons.location_on_outlined,
            hint: 'Contoh: Gedung A lantai 3, ruang 302',
            validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Lokasi wajib diisi';
          return null;
        }),
        const SizedBox(height: 14),

        // Time picker
        GestureDetector(
          onTap: _pickDateTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Waktu Kejadian',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(_waktuKejadian),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.edit_calendar_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Image picker
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: _selectedImage != null ? 200 : 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Upload Foto Barang',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap untuk memilih dari galeri',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: AppColors.white, size: 20),
                          onPressed: () =>
                              setState(() => _selectedImage = null),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Step 5: Optional Fields ─────────────────────────────────
  Widget _buildOptionalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reward (only for HILANG)
        if (_statusKejadian == 'HILANG') ...[
          const Text(
            'Reward untuk Penemu 🎁',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.rewardOptions.map((option) {
              final label = option['label'] as String;
              final value = option['value'] as int;
              final selected = _rewardNominal == value;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _rewardNominal = value;
                    if (value == 0) {
                      _rewardLabel = null;
                    } else if (value == -1) {
                      _rewardLabel = 'Manual';
                    } else if (value == -2) {
                      _rewardLabel = 'Rahasia 🤫';
                    } else {
                      _rewardLabel = label;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.reward.withValues(alpha: 0.15)
                        : AppColors.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          selected ? AppColors.reward : AppColors.divider,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.reward
                          : AppColors.textSecondary,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Manual reward input
          if (_rewardNominal == -1) ...[
            const SizedBox(height: 12),
            _buildTextField(
              _manualRewardController,
              'Nominal Reward (Rp)',
              Icons.attach_money_rounded,
              hint: 'Contoh: 25000',
              keyboardType: TextInputType.number,
              required: false,
            ),
          ],
          const SizedBox(height: 20),
        ],

        // Duration
        const Text(
          'Durasi Postingan ⏱',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Postingan akan otomatis terhapus setelah periode ini',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: AppConstants.durationOptions.map((option) {
            final label = option['label'] as String;
            final days = option['days'] as int;
            final selected = _durasiHari == days;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _durasiHari = days),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.divider,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Reusable TextField Builder ──────────────────────────────
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
      validator: validator ??
          (required
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return '$label wajib diisi';
                  }
                  return null;
                }
              : null),
    );
  }
}
