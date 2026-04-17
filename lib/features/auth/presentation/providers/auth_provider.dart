import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user.dart';

const _authBoxName = 'auth';
const _tokenKey = 'auth_token';
const _userKey = 'auth_user';

class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      state = state.copyWith(isLoading: true);
      AppLogger.logInfo('初始化认证状态', tag: 'Auth');

      if (!Hive.isBoxOpen(_authBoxName)) {
        await Hive.openBox(_authBoxName);
      }

      final box = Hive.box(_authBoxName);
      final token = box.get(_tokenKey) as String?;
      final userJson = box.get(_userKey);

      if (token != null && userJson != null) {
        ApiService.setToken(token);
        final user = User.fromJson(Map<String, dynamic>.from(userJson as Map));
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        AppLogger.logInfo('自动登录成功: ${user.username} (${user.role})', tag: 'Auth');
      } else {
        state = state.copyWith(isLoading: false);
        AppLogger.logInfo('未找到已保存的登录信息', tag: 'Auth');
      }
    } catch (e) {
      AppLogger.logError('初始化认证失败: $e', tag: 'Auth');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      AppLogger.logInfo('尝试登录: $username', tag: 'Auth');

      final response = await ApiService.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      if (response['success'] == true) {
        final token = response['data']['token'] as String;
        final userData = Map<String, dynamic>.from(response['data']['user'] as Map);
        final user = User.fromJson(userData);

        ApiService.setToken(token);

        if (!Hive.isBoxOpen(_authBoxName)) {
          await Hive.openBox(_authBoxName);
        }

        final box = Hive.box(_authBoxName);
        await box.put(_tokenKey, token);
        await box.put(_userKey, userData);

        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );

        AppLogger.logInfo('登录成功: ${user.username} (${user.role})', tag: 'Auth');
        return true;
      } else {
        final message = response['message'] ?? '登录失败';
        state = state.copyWith(isLoading: false, errorMessage: message);
        AppLogger.logWarn('登录失败: $message', tag: 'Auth');
        return false;
      }
    } catch (e) {
      AppLogger.logError('登录异常: $e', tag: 'Auth');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '网络错误，请检查网络连接',
      );
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      AppLogger.logInfo('尝试注册: $username', tag: 'Auth');

      final response = await ApiService.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        final token = response['data']['token'] as String;
        final userData = Map<String, dynamic>.from(response['data']['user'] as Map);
        final user = User.fromJson(userData);

        ApiService.setToken(token);

        if (!Hive.isBoxOpen(_authBoxName)) {
          await Hive.openBox(_authBoxName);
        }

        final box = Hive.box(_authBoxName);
        await box.put(_tokenKey, token);
        await box.put(_userKey, userData);

        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );

        AppLogger.logInfo('注册成功: ${user.username}', tag: 'Auth');
        return true;
      } else {
        final message = response['message'] ?? '注册失败';
        state = state.copyWith(isLoading: false, errorMessage: message);
        AppLogger.logWarn('注册失败: $message', tag: 'Auth');
        return false;
      }
    } catch (e) {
      AppLogger.logError('注册异常: $e', tag: 'Auth');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '网络错误，请检查网络连接',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.logInfo('用户登出', tag: 'Auth');

      if (Hive.isBoxOpen(_authBoxName)) {
        final box = Hive.box(_authBoxName);
        await box.delete(_tokenKey);
        await box.delete(_userKey);
      }

      ApiService.setToken(null);

      state = const AuthState();

      AppLogger.logInfo('登出成功', tag: 'Auth');
    } catch (e) {
      AppLogger.logError('登出异常: $e', tag: 'Auth');
      state = const AuthState();
    }
  }

  Future<void> refreshUser() async {
    try {
      if (!state.isAuthenticated) return;

      AppLogger.logInfo('刷新用户信息', tag: 'Auth');

      final response = await ApiService.get('/auth/me');

      if (response['success'] == true) {
        final userData = Map<String, dynamic>.from(response['data'] as Map);
        final user = User.fromJson(userData);

        if (Hive.isBoxOpen(_authBoxName)) {
          final box = Hive.box(_authBoxName);
          await box.put(_userKey, userData);
        }

        state = state.copyWith(user: user);
        AppLogger.logInfo('用户信息刷新成功', tag: 'Auth');
      }
    } catch (e) {
      AppLogger.logError('刷新用户信息失败: $e', tag: 'Auth');
    }
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
