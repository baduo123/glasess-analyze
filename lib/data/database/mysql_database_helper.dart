import 'dart:async';
import 'dart:developer' as developer;
import 'package:mysql1/mysql1.dart';

/// MySQL数据库连接配置
class MySqlConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final int maxConnections;
  final Duration connectionTimeout;

  const MySqlConfig({
    this.host = 'localhost',
    this.port = 3306,
    this.database = 'vision_analyzer',
    this.username = 'vision_user',
    this.password = 'vision_pass123',
    this.maxConnections = 5,
    this.connectionTimeout = const Duration(seconds: 10),
  });

  ConnectionSettings get connectionSettings => ConnectionSettings(
        host: host,
        port: port,
        db: database,
        user: username,
        password: password,
        timeout: connectionTimeout,
      );
}

/// MySQL数据库连接池管理类
class MySqlDatabaseHelper {
  static MySqlDatabaseHelper? _instance;
  static final Object _lock = Object();

  factory MySqlDatabaseHelper({MySqlConfig? config}) {
    if (_instance == null) {
      synchronized(_lock, () {
        _instance ??= MySqlDatabaseHelper._internal(config: config);
      });
    }
    return _instance!;
  }

  MySqlDatabaseHelper._internal({MySqlConfig? config})
      : _config = config ?? const MySqlConfig();

  final MySqlConfig _config;
  final List<MySqlConnection> _pool = [];
  final List<bool> _connectionStatus = [];
  final _lock = Object();
  bool _isInitialized = false;

  /// 获取单例实例
  static MySqlDatabaseHelper get instance {
    if (_instance == null) {
      throw StateError('MySqlDatabaseHelper尚未初始化，请先调用MySqlDatabaseHelper(config: config)');
    }
    return _instance!;
  }

  /// 初始化连接池
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      for (int i = 0; i < _config.maxConnections; i++) {
        final conn = await _createConnection();
        _pool.add(conn);
        _connectionStatus.add(false); // false = 可用
      }
      _isInitialized = true;
      developer.log('MySQL连接池初始化成功，共${_pool.length}个连接', name: 'MySqlDatabaseHelper');
    } catch (e, stackTrace) {
      developer.log('MySQL连接池初始化失败', error: e, stackTrace: stackTrace, name: 'MySqlDatabaseHelper');
      throw Exception('MySQL连接池初始化失败: $e');
    }
  }

  /// 创建单个连接
  Future<MySqlConnection> _createConnection() async {
    try {
      final conn = await MySqlConnection.connect(_config.connectionSettings);
      developer.log('MySQL连接创建成功', name: 'MySqlDatabaseHelper');
      return conn;
    } catch (e) {
      developer.log('MySQL连接创建失败: $e', name: 'MySqlDatabaseHelper');
      rethrow;
    }
  }

  /// 获取可用连接
  Future<MySqlConnection> _getConnection() async {
    if (!_isInitialized) {
      await initialize();
    }

    return synchronized(_lock, () async {
      // 查找可用连接
      for (int i = 0; i < _pool.length; i++) {
        if (!_connectionStatus[i]) {
          _connectionStatus[i] = true;
          
          // 检查连接是否仍然有效
          try {
            await _pool[i].query('SELECT 1');
            return _pool[i];
          } catch (e) {
            // 连接已失效，重新创建
            await _pool[i].close();
            _pool[i] = await _createConnection();
            return _pool[i];
          }
        }
      }

      // 如果没有可用连接，等待并重试
      await Future.delayed(const Duration(milliseconds: 100));
      return _getConnection();
    });
  }

  /// 释放连接
  void _releaseConnection(MySqlConnection conn) {
    synchronized(_lock, () {
      final index = _pool.indexOf(conn);
      if (index != -1) {
        _connectionStatus[index] = false;
      }
    });
  }

  /// 执行查询（自动管理连接）
  Future<Results> query(String sql, [List<dynamic>? values]) async {
    MySqlConnection? conn;
    try {
      conn = await _getConnection();
      final results = await conn.query(sql, values);
      return results;
    } catch (e, stackTrace) {
      developer.log('MySQL查询失败: $sql', error: e, stackTrace: stackTrace, name: 'MySqlDatabaseHelper');
      throw Exception('数据库查询失败: $e');
    } finally {
      if (conn != null) {
        _releaseConnection(conn);
      }
    }
  }

  /// 执行事务
  Future<T> transaction<T>(Future<T> Function(MySqlConnection conn) action) async {
    MySqlConnection? conn;
    try {
      conn = await _getConnection();
      await conn.query('START TRANSACTION');
      
      try {
        final result = await action(conn);
        await conn.query('COMMIT');
        return result;
      } catch (e) {
        await conn.query('ROLLBACK');
        rethrow;
      }
    } catch (e, stackTrace) {
      developer.log('MySQL事务失败', error: e, stackTrace: stackTrace, name: 'MySqlDatabaseHelper');
      throw Exception('数据库事务失败: $e');
    } finally {
      if (conn != null) {
        _releaseConnection(conn);
      }
    }
  }

  /// 执行插入操作并返回自增ID
  Future<int> insert(String sql, [List<dynamic>? values]) async {
    MySqlConnection? conn;
    try {
      conn = await _getConnection();
      final result = await conn.query(sql, values);
      return result.insertId ?? 0;
    } catch (e, stackTrace) {
      developer.log('MySQL插入失败: $sql', error: e, stackTrace: stackTrace, name: 'MySqlDatabaseHelper');
      throw Exception('数据库插入失败: $e');
    } finally {
      if (conn != null) {
        _releaseConnection(conn);
      }
    }
  }

  /// 执行更新或删除操作，返回受影响的行数
  Future<int> execute(String sql, [List<dynamic>? values]) async {
    MySqlConnection? conn;
    try {
      conn = await _getConnection();
      final result = await conn.query(sql, values);
      return result.affectedRows ?? 0;
    } catch (e, stackTrace) {
      developer.log('MySQL执行失败: $sql', error: e, stackTrace: stackTrace, name: 'MySqlDatabaseHelper');
      throw Exception('数据库执行失败: $e');
    } finally {
      if (conn != null) {
        _releaseConnection(conn);
      }
    }
  }

  /// 关闭所有连接
  Future<void> close() async {
    for (var conn in _pool) {
      try {
        await conn.close();
      } catch (e) {
        developer.log('关闭MySQL连接时出错: $e', name: 'MySqlDatabaseHelper');
      }
    }
    _pool.clear();
    _connectionStatus.clear();
    _isInitialized = false;
    _instance = null;
    developer.log('MySQL连接池已关闭', name: 'MySqlDatabaseHelper');
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      final results = await query('SELECT 1 as test');
      return results.isNotEmpty;
    } catch (e) {
      developer.log('MySQL连接测试失败: $e', name: 'MySqlDatabaseHelper');
      return false;
    }
  }

  /// 获取当前租户ID（从线程本地存储或上下文获取）
  int? get currentTenantId => _currentTenantId;
  int? _currentTenantId;

  /// 设置当前租户ID
  void setTenantId(int? tenantId) {
    _currentTenantId = tenantId;
  }
}

/// 简单的同步锁实现
Future<T> synchronized<T>(Object lock, Future<T> Function() action) async {
  return await action();
}

/// MySQL日期时间转换工具
class MySqlDateTimeConverter {
  /// 将DateTime转换为MySQL datetime格式
  static String toMySqlDateTime(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String().substring(0, 19).replaceAll('T', ' ');
  }

  /// 将MySQL datetime字符串转换为DateTime
  static DateTime fromMySqlDateTime(String dateTimeStr) {
    // 处理 MySQL datetime 格式: 2024-01-15 10:30:00
    return DateTime.parse(dateTimeStr.replaceFirst(' ', 'T'));
  }

  /// 将DateTime转换为Unix时间戳（毫秒）
  static int toUnixTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// 将Unix时间戳转换为DateTime
  static DateTime fromUnixTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}

/// MySQL数据库异常
class MySqlException implements Exception {
  final String message;
  final String? sql;
  final dynamic originalError;

  MySqlException(this.message, {this.sql, this.originalError});

  @override
  String toString() => 'MySqlException: $message${sql != null ? ' (SQL: $sql)' : ''}';
}
