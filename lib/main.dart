import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '视功能分析',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// 认证包装器
/// 根据认证状态决定显示登录页还是主页
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 检查Token是否有效
    if (authState.isAuthenticated) {
      // 验证Token是否过期
      final isValid = ref.read(authProvider.notifier).validateToken();
      if (isValid) {
        return const HomePage();
      } else {
        // Token过期，自动登出
        ref.read(authProvider.notifier).logout();
        return const LoginPage();
      }
    }

    return const LoginPage();
  }
}
