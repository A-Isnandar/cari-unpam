import 'package:flutter/material.dart';

class AppConstants {
  // User status options
  static const List<String> userStatuses = [
    'Mahasiswa',
    'Dosen',
    'Satpam',
    'Petugas Kebersihan',
    'Karyawan',
    'Lainnya',
  ];

  // Item categories
  static const List<Map<String, dynamic>> itemCategories = [
    {'label': 'KTM', 'icon': Icons.credit_card},
    {'label': 'Dompet', 'icon': Icons.account_balance_wallet},
    {'label': 'Helm', 'icon': Icons.sports_motorsports},
    {'label': 'Tas', 'icon': Icons.backpack},
    {'label': 'Buku', 'icon': Icons.menu_book},
    {'label': 'Lainnya', 'icon': Icons.more_horiz},
  ];

  // Reward options
  static const List<Map<String, dynamic>> rewardOptions = [
    {'label': 'Rp5k', 'value': 5000},
    {'label': 'Rp10k', 'value': 10000},
    {'label': 'Rp20k', 'value': 20000},
    {'label': 'Rp50k', 'value': 50000},
    {'label': 'Rp100k', 'value': 100000},
    {'label': 'Input Manual', 'value': -1},
    {'label': 'Rahasia', 'value': -2},
    {'label': 'Tidak Ada', 'value': 0},
  ];

  // Post duration options
  static const List<Map<String, dynamic>> durationOptions = [
    {'label': '7 Hari', 'days': 7},
    {'label': '14 Hari', 'days': 14},
    {'label': '1 Bulan', 'days': 30},
  ];
}
