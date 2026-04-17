import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    AppLogger.logInfo('登录页面初始化', tag: 'AuthUI');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildTitle(theme),
                    const SizedBox(height: 32),
                    if (!_isLogin) ...[
                      _buildEmailField(),
                      const SizedBox(height: 16),
                    ],
                    _buildUsernameField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(authState),
                    const SizedBox(height: 16),
                    if (authState.errorMessage != null)
                      _buildErrorMessage(authState.errorMessage!),
                    const SizedBox(height: 24),
                    _buildToggleModeButton(theme),
                    const SizedBox(height: 32),
                    _buildTestAccountsHint(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A73E8), Color(0xFF4285F4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.camera_alt,
        color: Colors.white,
        size: 50,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Column(
      children: [
        Text(
          '智眸AI相机',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? '欢迎回来，请登录您的账号' : '创建新账号，开始智能摄影之旅',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white60,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '邮箱',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入邮箱';
        }
        if (!value.contains('@')) {
          return '请输入有效的邮箱地址';
        }
        return null;
      },
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '用户名',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入用户名';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: '密码',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A73E8)),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入密码';
        }
        if (value.length < 6) {
          return '密码长度至少6位';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(AuthState authState) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: authState.isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A73E8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: authState.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isLogin ? '登 录' : '注 册',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    AppLogger.logInfo('提交${_isLogin ? "登录" : "注册"}表单', tag: 'AuthUI');

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    bool success;
    if (_isLogin) {
      success = await ref.read(authProvider.notifier).login(username, password);
    } else {
      success = await ref.read(authProvider.notifier).register(
            username,
            '${username}@aicam.com',
            password,
          );
    }

    if (success && mounted) {
      AppLogger.logInfo('${_isLogin ? "登录" : "注册"}成功，跳转主页', tag: 'AuthUI');
      
      final user = ref.read(authProvider).user!;
      if (user.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('管理员 ${user.username}，欢迎回来！'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      context.go('/camera');
    } else if (mounted && ref.read(authProvider).errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleModeButton(ThemeData theme) {
    final isLoginText = _isLogin ? '还没有账号？' : '已有账号？';
    final actionText = _isLogin ? ' 立即注册' : ' 立即登录';
    
    return TextButton(
      onPressed: () {
        setState(() {
          _isLogin = !_isLogin;
          _formKey.currentState?.reset();
        });
        AppLogger.logInfo('切换到${_isLogin ? "登录" : "注册"}模式', tag: 'AuthUI');
      },
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14),
          children: [
            TextSpan(
              text: isLoginText,
              style: const TextStyle(color: Colors.white60),
            ),
            TextSpan(
              text: actionText,
              style: const TextStyle(
                color: Color(0xFF1A73E8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestAccountsHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[300], size: 18),
              const SizedBox(width: 8),
              Text(
                '测试账号',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccountRow('管理员', 'admin', 'admin123', Icons.admin_panel_settings),
          const SizedBox(height: 8),
          _buildAccountRow('普通用户', 'test', 'test123', Icons.person),
        ],
      ),
    );
  }

  Widget _buildAccountRow(String role, String username, String password, IconData icon) {
    return InkWell(
      onTap: () {
        _usernameController.text = username;
        _passwordController.text = password;
        AppLogger.logInfo('填充测试账号: $username', tag: 'AuthUI');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                role,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Text(
              '$username / $password',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
