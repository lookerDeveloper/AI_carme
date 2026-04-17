import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/storage/local_storage.dart';
import 'core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.logInfo('🚀 应用启动中...', tag: 'App');
  await LocalStorage.initialize();
  AppLogger.logInfo('✅ 本地存储初始化完成', tag: 'App');
  await AppLogger.initialize(minLevel: LogLevel.debug);
  AppLogger.logInfo('📱 日志系统就绪，开始运行', tag: 'App');
  runApp(const ProviderScope(child: AICamCoachApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return appRouter(ref);
});

class AICamCoachApp extends ConsumerWidget {
  const AICamCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '智眸AI相机',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
