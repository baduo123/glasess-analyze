import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/auth_service.dart';

/// 认证状态
@immutable
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? token;
  final String? userId;
  final String? tenantId;
  final String? tenantCode;
  final String? role;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.token,
    this.userId,
    this.tenantId,
    this.tenantCode,
    this.role,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? token,
    String? userId,
    String? tenantId,
    String? tenantCode,
    String? role,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      tenantCode: tenantCode ?? this.tenantCode,
      role: role ?? this.role,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, isLoading: $isLoading, tenantCode: $tenantCode, role: $role, error: $error)';
  }
}

/// 认证状态 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AuthState());

  /// 登录
  Future<void> login({
    required String tenantCode,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final token = await _authService.login(tenantCode, username, password);
      final payload = _authService.verifyToken(token);

      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        token: token,
        userId: payload.sub,
        tenantId: payload.tenantId,
        tenantCode: payload.tenantCode,
        role: payload.role,
        clearError: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        clearError: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '登录失败: $e',
        clearError: false,
      );
    }
  }

  /// 登出
  void logout() {
    state = const AuthState();
  }

  /// 刷新 Token
  Future<void> refreshToken() async {
    final currentToken = state.token;
    if (currentToken == null) return;

    try {
      final newToken = _authService.refreshToken(currentToken);
      final payload = _authService.verifyToken(newToken);

      state = state.copyWith(
        token: newToken,
        userId: payload.sub,
        tenantId: payload.tenantId,
        tenantCode: payload.tenantCode,
        role: payload.role,
      );
    } on AuthException catch (e) {
      // Token 刷新失败，需要重新登录
      state = state.copyWith(
        isAuthenticated: false,
        token: null,
        userId: null,
        tenantId: null,
        tenantCode: null,
        role: null,
        error: '会话已过期，请重新登录',
      );
    }
  }

  /// 检查是否需要刷新 Token（在 Token 即将过期时）
  Future<void> checkAndRefreshToken() async {
    final currentToken = state.token;
    if (currentToken == null || !state.isAuthenticated) return;

    try {
      final payload = _authService.verifyToken(currentToken);
      
      // 如果 Token 将在 1 天内过期，则刷新
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final oneDay = 24 * 60 * 60;
      
      if (payload.exp - now < oneDay) {
        await refreshToken();
      }
    } on AuthException {
      // Token 无效，登出
      logout();
    }
  }

  /// 验证当前 Token
  bool validateToken() {
    final currentToken = state.token;
    if (currentToken == null) return false;

    try {
      _authService.verifyToken(currentToken);
      return true;
    } on AuthException {
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// AuthService Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// AuthNotifier Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// 认证状态选择器 Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<AuthState>((ref) {
  return ref.watch(authProvider);
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});
