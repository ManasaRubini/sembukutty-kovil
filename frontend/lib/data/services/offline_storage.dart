import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

class OfflineStorageService {
  static const String _kCachedStaffKey = 'offline_cached_staff';
  static const String _kCachedMembersKey = 'offline_cached_members';
  static const String _kPendingTxnsKey = 'offline_pending_txns';
  static const String _kCachedDashboardKey = 'offline_cached_dashboard_';
  static const String _kServerIpKey = 'custom_server_url';

  // Seed default staff members for first launch offline mode
  static final List<Map<String, dynamic>> _seedStaff = [
    {
      'id': 'member-1-default',
      'name': 'Sembukutty Kovil Member 1',
      'phone': '9876543210',
      'email': 'member1@kovil.com',
      'is_active': true,
      'is_approved': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      'id': 'member-2-default',
      'name': 'Sembukutty Kovil Member 2',
      'phone': '9876543211',
      'email': 'member2@kovil.com',
      'is_active': true,
      'is_approved': true,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    },
  ];

  // ─── Staff Cache ─────────────────────────────────────────────────────────────
  static Future<void> saveStaffList(List<StaffModel> staffList) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(staffList.map((s) => s.toJson()).toList());
    await prefs.setString(_kCachedStaffKey, jsonStr);
  }

  static Future<List<StaffModel>> getStaffList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kCachedStaffKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List list = jsonDecode(jsonStr);
        return list.map((e) => StaffModel.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error parsing cached staff: $e');
      }
    }
    // Return seed staff if no cache exists yet
    return _seedStaff.map((e) => StaffModel.fromJson(e)).toList();
  }

  // ─── Members Cache ───────────────────────────────────────────────────────────
  static Future<void> saveMembersList(List<MemberModel> members) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(members.map((m) => m.toJson()).toList());
    await prefs.setString(_kCachedMembersKey, jsonStr);
  }

  static Future<List<MemberModel>> searchMembers(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kCachedMembersKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List list = jsonDecode(jsonStr);
        final all = list.map((e) => MemberModel.fromJson(e)).toList();
        if (query.trim().isEmpty) return all;
        final q = query.trim().toLowerCase();
        return all
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.phone.contains(q) ||
                m.address.toLowerCase().contains(q))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  // ─── Offline Pending Transactions Queue ──────────────────────────────────────
  static Future<TransactionModel> saveOfflineTransaction(Map<String, dynamic> txnData) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingList = prefs.getStringList(_kPendingTxnsKey) ?? [];

    final offlineId = 'offline-${DateTime.now().millisecondsSinceEpoch}';
    final type = txnData['type'] ?? 'tax';
    final prefix = type == 'expense' ? 'VOUCHER-OFFLINE' : type == 'transfer' ? 'TRANS-OFFLINE' : 'REC-OFFLINE';
    final serial = '$prefix-${pendingList.length + 1}';

    final fullTxn = {
      'id': offlineId,
      'staff_id': txnData['staff_id'] ?? '',
      'type': type,
      'date': txnData['date'] ?? DateTime.now().toIso8601String().split('T')[0],
      'amount': (txnData['amount'] as num?)?.toDouble() ?? 0.0,
      'mode': txnData['mode'] ?? 'cash',
      'member_id': txnData['member_id'],
      'member_name': txnData['member_name'] ?? '',
      'member_phone': txnData['member_phone'] ?? '',
      'address': txnData['address'] ?? '',
      'purpose': txnData['purpose'] ?? '',
      'remarks': txnData['remarks'] ?? '',
      'paid_to': txnData['paid_to'] ?? '',
      'direction': txnData['direction'],
      'serial_number': serial,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    pendingList.add(jsonEncode(fullTxn));
    await prefs.setStringList(_kPendingTxnsKey, pendingList);

    return TransactionModel.fromJson(fullTxn);
  }

  static Future<List<TransactionModel>> getPendingTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingList = prefs.getStringList(_kPendingTxnsKey) ?? [];
    return pendingList.map((str) => TransactionModel.fromJson(jsonDecode(str))).toList();
  }

  static Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingList = prefs.getStringList(_kPendingTxnsKey) ?? [];
    return pendingList.length;
  }

  static Future<int> syncPendingTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> pendingList = prefs.getStringList(_kPendingTxnsKey) ?? [];
    if (pendingList.isEmpty) return 0;

    int synced = 0;
    List<String> remaining = [];

    for (var jsonStr in pendingList) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        // Remove temporary offline client IDs before posting to server
        final payload = Map<String, dynamic>.from(data);
        payload.remove('id');
        payload.remove('serial_number');

        await ApiClient.instance.post('/api/transactions', data: payload);
        synced++;
      } catch (e) {
        debugPrint('Sync failed for item: $e');
        remaining.add(jsonStr);
      }
    }

    await prefs.setStringList(_kPendingTxnsKey, remaining);
    return synced;
  }

  // ─── Dashboard Cache ─────────────────────────────────────────────────────────
  static Future<void> saveDashboardData(String staffId, DashboardData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kCachedDashboardKey$staffId', jsonEncode(data.toJson()));
  }

  static Future<DashboardData?> getDashboardData(String staffId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('$_kCachedDashboardKey$staffId');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        return DashboardData.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }
    return null;
  }

  // ─── Server URL Setting ─────────────────────────────────────────────────────
  static Future<void> setCustomServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = url.trim();
    if (clean.isNotEmpty) {
      await prefs.setString(_kServerIpKey, clean);
      ApiConfig.baseUrl = clean;
    }
  }

  static Future<String> getCustomServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kServerIpKey) ?? ApiConfig.baseUrl;
  }
}
