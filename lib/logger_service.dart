import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// 日志服务 - 统一管理应用日志
class LoggerService {
  static LoggerService? _instance;
  static Logger? _logger;
  static File? _logFile;
  
  // 单例模式
  static LoggerService get instance {
    _instance ??= LoggerService._();
    return _instance!;
  }
  
  LoggerService._();
  
  /// 初始化日志系统
  Future<void> initialize() async {
    try {
      // 获取日志目录
      final logDir = await _getLogDirectory();
      
      // 创建日志文件（按日期命名）
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      _logFile = File('${logDir.path}/app_$dateStr.log');
      
      // 清理旧日志（保留最近7天）
      await _cleanOldLogs(logDir);
      
      // 配置Logger
      _logger = Logger(
        printer: _CustomLogPrinter(),
        output: _FileOutput(_logFile!),
        level: Level.debug, // 记录所有级别的日志
      );
      
      info('========================================');
      info('日志系统初始化完成');
      info('日志文件: ${_logFile!.path}');
      info('版本: v1.3.2');
      info('启动时间: ${DateTime.now()}');
      info('========================================');
    } catch (e) {
      print('日志系统初始化失败: $e');
    }
  }
  
  /// 获取日志目录
  Future<Directory> _getLogDirectory() async {
    // 尝试使用应用数据目录
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDir.path}/MouseControl/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      return logDir;
    } catch (e) {
      // 如果失败，使用当前目录的logs文件夹
      final logDir = Directory('logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      return logDir;
    }
  }
  
  /// 清理旧日志（保留最近N天）
  Future<void> _cleanOldLogs(Directory logDir, {int keepDays = 7}) async {
    try {
      final now = DateTime.now();
      final files = await logDir.list().toList();
      
      for (var file in files) {
        if (file is File && file.path.endsWith('.log')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;
          
          if (age > keepDays) {
            await file.delete();
            print('已删除旧日志: ${file.path}');
          }
        }
      }
    } catch (e) {
      print('清理旧日志失败: $e');
    }
  }
  
  /// Debug日志
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.d(message, error: error, stackTrace: stackTrace);
    print('[DEBUG] $message');
  }
  
  /// Info日志
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.i(message, error: error, stackTrace: stackTrace);
    print('[INFO] $message');
  }
  
  /// Warning日志
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.w(message, error: error, stackTrace: stackTrace);
    print('[WARNING] $message');
  }
  
  /// Error日志
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
    print('[ERROR] $message');
  }
  
  /// 获取当前日志文件路径
  String? get logFilePath => _logFile?.path;
  
  /// 关闭日志系统
  void close() {
    info('========================================');
    info('日志系统关闭');
    info('结束时间: ${DateTime.now()}');
    info('========================================');
    _logger?.close();
  }
}

/// 自定义日志格式化器
class _CustomLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level];
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final message = event.message;
    final time = DateTime.now();
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
                   '${time.minute.toString().padLeft(2, '0')}:'
                   '${time.second.toString().padLeft(2, '0')}.'
                   '${time.millisecond.toString().padLeft(3, '0')}';
    
    final levelStr = event.level.toString().split('.').last.toUpperCase().padRight(7);
    
    // 文件日志格式: [时间] [级别] 消息
    final logLine = '[$timeStr] [$levelStr] $message';
    
    // 如果有错误信息，添加到下一行
    if (event.error != null) {
      return [logLine, 'Error: ${event.error}'];
    }
    
    // 如果有堆栈跟踪，添加到日志
    if (event.stackTrace != null) {
      return [logLine, event.stackTrace.toString()];
    }
    
    return [logLine];
  }
}

/// 文件输出
class _FileOutput extends LogOutput {
  final File file;
  
  _FileOutput(this.file);
  
  @override
  void output(OutputEvent event) {
    try {
      final buffer = StringBuffer();
      for (var line in event.lines) {
        buffer.writeln(line);
      }
      file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
    } catch (e) {
      print('写入日志文件失败: $e');
    }
  }
}

