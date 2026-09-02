import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/models.dart';
import 'offline_storage.dart';

// ─── Auth Service ─────────────────────────────────────────────────────────────
class AuthService {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> getSetupStatus() async {
    try {
      final r = await _client.get('/api/auth/setup-status');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> adminRegister({
    required String username,
    required String password,
    String? phone,
    String? email,
  }) async {
    try {
      final r = await _client.post('/api/auth/admin-register', data: {
        'username': username,
        'password': password,
        'phone': phone ?? '',
        'email': email ?? '',
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> staffRegister({
    required String name,
    required String phone,
    String? email,
    required String pin,
  }) async {
    try {
      final r = await _client.post('/api/auth/staff-register', data: {
        'name': name,
        'phone': phone,
        'email': email ?? '',
        'pin': pin,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> sendOtp({
    required String email,
    String name = '',
    String phone = '',
    String pin = '1234',
  }) async {
    try {
      final r = await _client.post('/api/auth/send-otp', data: {
        'email': email,
        'name': name,
        'phone': phone,
        'pin': pin,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final r = await _client.post('/api/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      final r = await _client.post('/api/auth/resend-otp', data: {
        'email': email,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> forgotPasswordSendOtp({
    required String email,
    String accountType = 'member',
    String? staffId,
  }) async {
    try {
      final r = await _client.post('/api/auth/forgot-password/send-otp', data: {
        'email': email,
        'account_type': accountType,
        if (staffId != null) 'staff_id': staffId,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> forgotPasswordVerifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final r = await _client.post('/api/auth/forgot-password/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> forgotPasswordReset({
    required String email,
    required String accountType,
    required String otp,
    required String newPasswordOrPin,
    String? staffId,
  }) async {
    try {
      final r = await _client.post('/api/auth/forgot-password/reset', data: {
        'email': email,
        'account_type': accountType,
        'otp': otp,
        'new_password_or_pin': newPasswordOrPin,
        if (staffId != null) 'staff_id': staffId,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    try {
      final r = await _client.post('/api/auth/admin-login', data: {
        'username': username,
        'password': password,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> staffLogin(String usernameOrId, String pin) async {
    try {
      final r = await _client.post('/api/auth/staff-login', data: {
        'identifier': usernameOrId,
        'staff_id': usernameOrId,
        'pin': pin,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyResetRequest({
    required String accountType,
    required String identifier,
    String? staffId,
  }) async {
    try {
      final r = await _client.post('/api/auth/verify-reset-request', data: {
        'account_type': accountType,
        'identifier': identifier,
        if (staffId != null) 'staff_id': staffId,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> resetPasswordOrPin({
    required String resetToken,
    required String newValue,
  }) async {
    try {
      final r = await _client.post('/api/auth/reset-password-or-pin', data: {
        'reset_token': resetToken,
        'new_value': newValue,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─── Staff Service ────────────────────────────────────────────────────────────
class StaffService {
  final _client = ApiClient.instance;

  Future<List<StaffModel>> getAll() async {
    try {
      final r = await _client.get('/api/staff');
      final list = (r.data as List).map((e) => StaffModel.fromJson(e)).toList();
      await OfflineStorageService.saveStaffList(list);
      return list;
    } catch (_) {
      return await OfflineStorageService.getStaffList();
    }
  }

  Future<List<StaffModel>> getPending() async {
    try {
      final r = await _client.get('/api/staff/pending');
      return (r.data as List).map((e) => StaffModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<StaffModel> approve(String id, {String? verificationCode}) async {
    try {
      final r = await _client.post('/api/staff/approve/$id', data: {
        if (verificationCode != null) 'verification_code': verificationCode,
      });
      return StaffModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reject(String id) async {
    try {
      await _client.post('/api/staff/reject/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<StaffModel> create(String name, {String? phone, String? email, String? pin}) async {
    try {
      final r = await _client.post('/api/staff', data: {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (pin != null) 'pin': pin,
      });
      return StaffModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<StaffModel> update(String id, {String? name, String? phone, String? email, String? pin, bool? isActive}) async {
    try {
      final r = await _client.put('/api/staff/$id', data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (pin != null) 'pin': pin,
        if (isActive != null) 'is_active': isActive,
      });
      return StaffModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deactivate(String id) async {
    try {
      await _client.delete('/api/staff/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─── Member Service ───────────────────────────────────────────────────────────
class MemberService {
  final _client = ApiClient.instance;

  Future<List<MemberModel>> search(String query) async {
    try {
      final r = await _client.get('/api/members/search', params: {'q': query, 'limit': 25});
      final list = (r.data as List).map((e) => MemberModel.fromJson(e)).toList();
      await OfflineStorageService.saveMembersList(list);
      return list;
    } catch (_) {
      return await OfflineStorageService.searchMembers(query);
    }
  }

  Future<MemberModel> create({required String name, String phone = '', String address = ''}) async {
    try {
      final r = await _client.post('/api/members', data: {
        'name': name, 'phone': phone, 'address': address
      });
      return MemberModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<MemberModel> update(String id, {String? name, String? phone, String? address}) async {
    try {
      final r = await _client.put('/api/members/$id', data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      });
      return MemberModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.delete('/api/members/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─── Opening Balance Service ──────────────────────────────────────────────────
class OpeningBalanceService {
  final _client = ApiClient.instance;

  Future<OpeningBalanceModel?> get() async {
    try {
      final r = await _client.get('/api/opening-balances');
      return OpeningBalanceModel.fromJson(r.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioError(e);
    }
  }

  Future<OpeningBalanceModel> create({
    required double bankBalance,
    required double cashBalance,
    required String cashHolderStaffId,
  }) async {
    try {
      final r = await _client.post('/api/opening-balances', data: {
        'bank_balance': bankBalance,
        'cash_balance': cashBalance,
        'cash_holder_staff_id': cashHolderStaffId,
      });
      return OpeningBalanceModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<OpeningBalanceModel> update({double? bankBalance, double? cashBalance, String? cashHolderStaffId}) async {
    try {
      final r = await _client.put('/api/opening-balances', data: {
        if (bankBalance != null) 'bank_balance': bankBalance,
        if (cashBalance != null) 'cash_balance': cashBalance,
        if (cashHolderStaffId != null) 'cash_holder_staff_id': cashHolderStaffId,
      });
      return OpeningBalanceModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─── Transaction Service ──────────────────────────────────────────────────────
class TransactionService {
  final _client = ApiClient.instance;

  Future<TransactionModel> create(Map<String, dynamic> data) async {
    try {
      final r = await _client.post('/api/transactions', data: data);
      return TransactionModel.fromJson(r.data);
    } catch (_) {
      return await OfflineStorageService.saveOfflineTransaction(data);
    }
  }

  Future<List<TransactionModel>> list({
    String? staffId,
    String? type,
    String? dateFrom,
    String? dateTo,
    int limit = 500,
  }) async {
    try {
      final r = await _client.get('/api/transactions', params: {
        if (staffId != null) 'staff_id': staffId,
        if (type != null) 'type': type,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        'limit': limit,
      });
      return (r.data as List).map((e) => TransactionModel.fromJson(e)).toList();
    } catch (_) {
      return await OfflineStorageService.getPendingTransactions();
    }
  }

  Future<TransactionModel> getById(String id) async {
    try {
      final r = await _client.get('/api/transactions/$id');
      return TransactionModel.fromJson(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.delete('/api/transactions/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─── Dashboard Service ────────────────────────────────────────────────────────
class DashboardService {
  final _client = ApiClient.instance;

  Future<DashboardData> get(String staffId) async {
    try {
      final r = await _client.get('/api/dashboard', params: {'staff_id': staffId});
      final data = DashboardData.fromJson(r.data);
      await OfflineStorageService.saveDashboardData(staffId, data);
      return data;
    } catch (_) {
      final cached = await OfflineStorageService.getDashboardData(staffId);
      if (cached != null) return cached;
      final pending = await OfflineStorageService.getPendingTransactions();
      return DashboardData(
        taxCollected: 0,
        donations: 0,
        expenses: 0,
        income: 0,
        net: 0,
        myCash: 0,
        bankBalance: 0,
        totalCash: 0,
        grandTotal: 0,
        recentTransactions: pending,
      );
    }
  }
}

// ─── Reports Service ──────────────────────────────────────────────────────────
class ReportsService {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> collections({
    required String scope,
    String? staffId,
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final r = await _client.get('/api/reports/collections', params: {
        'scope': scope,
        if (staffId != null) 'staff_id': staffId,
        'date_from': dateFrom,
        'date_to': dateTo,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> expenses({
    required String scope,
    String? staffId,
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final r = await _client.get('/api/reports/expenses', params: {
        'scope': scope,
        if (staffId != null) 'staff_id': staffId,
        'date_from': dateFrom,
        'date_to': dateTo,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> balances({
    required String scope,
    String? staffId,
    String? asOf,
  }) async {
    try {
      final r = await _client.get('/api/reports/balances', params: {
        'scope': scope,
        if (staffId != null) 'staff_id': staffId,
        if (asOf != null) 'as_of': asOf,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─── Documents Service ────────────────────────────────────────────────────────
class DocumentsService {
  final _client = ApiClient.instance;

  Future<List<TransactionModel>> search({
    String? query,
    String? docType,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final r = await _client.get('/api/documents', params: {
        if (query != null && query.isNotEmpty) 'search': query,
        if (docType != null && docType != 'all') 'doc_type': docType,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
      });
      return (r.data as List).map((e) => TransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─── Backup Service ───────────────────────────────────────────────────────────
class BackupService {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> export() async {
    try {
      final r = await _client.get('/api/backup/export');
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<int>> exportExcelBytes({String? dateFrom, String? dateTo, String prefix = 'backup-1'}) async {
    try {
      final r = await _client.dio.get(
        '/api/backup/export-excel',
        queryParameters: {
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
          'prefix': prefix,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return r.data as List<int>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> resetAccountingData({double bankBalance = 0.0, double cashBalance = 0.0}) async {
    try {
      final r = await _client.post('/api/backup/reset-accounting-data', data: {
        'bank_balance': bankBalance,
        'cash_balance': cashBalance,
      });
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

