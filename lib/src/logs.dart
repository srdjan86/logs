import 'log_manager.dart';

/// A function that encodes a given object as a JSON-encodable map.
typedef ToJsonEncodable = Map<dynamic, dynamic>? Function(dynamic);

/// Enable (or disable) logging for all events on the given [channel].
void enableLogging(String channel, {bool enable = true}) {
  logManager.enableLogging(channel, enable: enable);
}

/// Logs a message conditionally if the given identifying event [channel] is
/// enabled (if `shouldLog(channel)` is true).
///
/// An optional map of JSON-encodable data can be provided as [data].
///
/// Logging for a given event channel can be enabled programmatically via
/// [enableLogging] or using a VM service call.
///
/// @see enableLogging
void log(
  String channel,
  String message, {
  required Map data,
  required DateTime time,
  ToJsonEncodable? toJsonEncodable,
  required int level,
  required StackTrace stackTrace,
}) {
  logManager.log(
    channel,
    message,
    data: data,
    toJsonEncodable: toJsonEncodable,
    time: time,
    level: level,
    stackTrace: stackTrace,
  );
}

/// Register a logging channel with the given [name] and optional [description].
void registerLoggingChannel(String name, {String? description}) {
  logManager.registerChannel(name, description: description);
}

/// Returns true if events on the given event [channel] should be logged.
bool shouldLog(String channel) => logManager.shouldLog(channel);

class Log {
  final String channel;

  Log(this.channel, {String? description}) {
    if (!logManager.channelDescriptions.containsKey(channel)) {
      logManager.registerChannel(channel, description: description);
    }
  }

  bool get enabled => logManager.shouldLog(channel);

  set enabled(enabled) {
    logManager.enableLogging(channel, enable: enabled);
  }

  /// @see [LogManager.log]
  void log(
    String message, {
    Map? data,
    ToJsonEncodable? toJsonEncodable,
    DateTime? time,
    int? level,
    StackTrace? stackTrace,
  }) {
    logManager.log(
      channel,
      message,
      data: data,
      toJsonEncodable: toJsonEncodable,
      time: time,
      level: level,
      stackTrace: stackTrace,
    );
  }
}
