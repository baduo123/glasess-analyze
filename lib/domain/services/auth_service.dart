import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mysql1/mysql1.dart';

/// JWT Payload 数据结构
class JWTPayload {
  final String sub;
  final String tenantId;
  final String tenantCode;
  final String role;
  final int iat;
  final int exp;

  JWTPayload({
    required this.sub,
    required this.tenantId,
    required this.tenantCode,
    required this.role,
    required this.iat,
    required this.exp,
  });

  factory JWTPayload.fromJson(Map<String, dynamic> json) {
    return JWTPayload(
      sub: json['sub'] as String,
      tenantId: json['tenant_id'] as String,
      tenantCode: json['tenant_code'] as String,
      role: json['role'] as String,
      iat: json['iat'] as int,
      exp: json['exp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': sub,
      'tenant_id': tenantId,
      'tenant_code': tenantCode,
      'role': role,
      'iat': iat,
      'exp': exp,
    };
  }

  bool get isExpired => DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp;
}

/// 认证异常
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

/// 认证服务
class AuthService {
  // JWT 密钥 - 实际生产环境应该从环境变量或安全存储获取
  static const String _jwtSecret = 'your-super-secret-jwt-key-change-in-production';
  
  // Token 有效期：7天
  static const int _tokenExpiryDays = 7;
  
  // 数据库连接配置 - 应该从配置文件读取
  static const String _dbHost = 'localhost';
  static const int _dbPort = 3306;
  static const String _dbUser = 'root';
  static const String _dbPassword = 'password';
  static const String _dbName = 'vision_analyzer';

  /// 使用简单的哈希算法（Web兼容）
  String hashPassword(String password, {String? salt}) {
    final actualSalt = salt ?? _generateSalt();
    
    // 简单的 SHA256 哈希
    final bytes = utf8.encode(password + actualSalt);
    final digest = sha256.convert(bytes);
    final hash = base64Encode(digest.bytes);
    
    // 返回 base64 编码的哈希和盐
    return '\$2a\$\$${base64Encode(utf8.encode(actualSalt))}\$$hash';
  }

  /// 生成随机盐值
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// 验证密码
  bool verifyPassword(String password, String hash) {
    try {
      // 解析哈希字符串
      final parts = hash.split('\$');
      if (parts.length < 4) return false;
      
      final salt = utf8.decode(base64Decode(parts[2]));
      final expectedHash = parts[3];
      
      // 使用相同的盐值重新哈希密码
      final newHash = hashPassword(password, salt: salt);
      final newParts = newHash.split('\$');
      
      // 比较哈希值
      return newParts[3] == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// 验证 bcrypt 格式的密码（用于验证数据库中的bcrypt哈希）
  bool verifyBcryptPassword(String password, String bcryptHash) {
    // 这里我们模拟 bcrypt 验证
    // 实际项目中应该使用 bcrypt 库
    // 对于测试账号 admin123，我们使用简单的字符串比较
    // 实际 bcrypt 哈希: \$2a\$10\$...
    
    if (bcryptHash.startsWith('\$2a\$') || bcryptHash.startsWith('\$2b\$')) {
      // 如果是标准的 bcrypt 哈希，使用我们的 verifyPassword
      // 注意：这不是真正的 bcrypt，只是为了演示
      // 在生产环境中应该使用专门的 bcrypt 库
      return verifyPassword(password, bcryptHash);
    }
    
    return false;
  }

  /// 登录并生成 JWT Token
  Future<String> login(String tenantCode, String username, String password) async {
    try {
      // 连接数据库
      final conn = await MySqlConnection.connect(
        ConnectionSettings(
          host: _dbHost,
          port: _dbPort,
          user: _dbUser,
          password: _dbPassword,
          db: _dbName,
        ),
      );

      try {
        // 查询租户
        final tenantResult = await conn.query(
          'SELECT id, code, status FROM tenants WHERE code = ?',
          [tenantCode],
        );

        if (tenantResult.isEmpty) {
          throw AuthException('租户不存在');
        }

        final tenant = tenantResult.first;
        if (tenant['status'] != 'active') {
          throw AuthException('租户已被禁用');
        }

        final tenantId = tenant['id'].toString();

        // 查询用户
        final userResult = await conn.query(
          'SELECT id, username, password_hash, role, status FROM users WHERE username = ? AND tenant_id = ?',
          [username, tenantId],
        );

        if (userResult.isEmpty) {
          throw AuthException('用户名或密码错误');
        }

        final user = userResult.first;
        final storedHash = user['password_hash'] as String;

        // 验证密码
        if (!verifyPassword(password, storedHash) && !verifyBcryptPassword(password, storedHash)) {
          throw AuthException('用户名或密码错误');
        }

        if (user['status'] != 'active') {
          throw AuthException('用户已被禁用');
        }

        // 生成 JWT Token
        final token = _generateToken(
          userId: user['id'].toString(),
          tenantId: tenantId,
          tenantCode: tenantCode,
          role: user['role'] as String,
        );

        return token;
      } finally {
        await conn.close();
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('登录失败: $e');
    }
  }

  /// 生成 JWT Token
  String _generateToken({
    required String userId,
    required String tenantId,
    required String tenantCode,
    required String role,
  }) {
    final now = DateTime.now();
    final expiry = now.add(Duration(days: _tokenExpiryDays));
    
    final payload = JWTPayload(
      sub: userId,
      tenantId: tenantId,
      tenantCode: tenantCode,
      role: role,
      iat: now.millisecondsSinceEpoch ~/ 1000,
      exp: expiry.millisecondsSinceEpoch ~/ 1000,
    );

    final jwt = JWT(
      payload.toJson(),
      issuer: 'vision-analyzer',
    );

    return jwt.sign(
      SecretKey(_jwtSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: Duration(days: _tokenExpiryDays),
    );
  }

  /// 验证 JWT Token
  JWTPayload verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final payload = JWTPayload.fromJson(jwt.payload as Map<String, dynamic>);
      
      if (payload.isExpired) {
        throw AuthException('Token 已过期');
      }
      
      return payload;
    } on JWTExpiredException {
      throw AuthException('Token 已过期');
    } on JWTException catch (e) {
      throw AuthException('Token 验证失败: ${e.message}');
    }
  }

  /// 刷新 Token
  String refreshToken(String token) {
    try {
      final payload = verifyToken(token);
      
      // 生成新的 Token
      return _generateToken(
        userId: payload.sub,
        tenantId: payload.tenantId,
        tenantCode: payload.tenantCode,
        role: payload.role,
      );
    } on AuthException {
      rethrow;
    }
  }

  /// 从 Token 获取用户 ID
  String? getUserIdFromToken(String token) {
    try {
      final payload = verifyToken(token);
      return payload.sub;
    } catch (_) {
      return null;
    }
  }

  /// 从 Token 获取租户 ID
  String? getTenantIdFromToken(String token) {
    try {
      final payload = verifyToken(token);
      return payload.tenantId;
    } catch (_) {
      return null;
    }
  }
}
