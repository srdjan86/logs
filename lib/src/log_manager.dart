import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:meta/meta.dart';

import 'channels/http.dart';
import 'logs.dart';

/// The shared manager instance.
final LogManager logManager = LogManager()..addListener(_sendToDeveloperLog);

void _sendToDeveloperLog(
  String channel,
  String message,
  Object? data,
  DateTime? time,
  int? level,
  StackTrace? stackTrace,
) {
  developer.log(
    message,
    name: channel,
    time: time,
    error: data,
    level: level ?? 0,
    stackTrace: stackTrace,
  );
}

typedef LogListener = void Function(
  String channel,
  String message,
  Object? data,
  DateTime? time,
  int? level,
  StackTrace? stackTrace,
);

typedef _ServiceExtensionCallback = Future<Map<String, dynamic>> Function(
    Map<String, String> parameters);

typedef _ChannelInstallHandler = bool Function(String name);

/// Provides hooks for channel installation.
abstract class ChannelInstallHandler {
  void installChannel(String name);
}

/// Exception thrown on logging configuration errors.
class LoggingException extends Error implements Exception {
  /// Message describing the exception.
  final String message;

  LoggingException(this.message);

  @override
  String toString() => 'Logging exception: $message';
}

/// Manages loggers.
///
/// * To create logging channels, see [registerChannel].
/// * To enable or disable a logging channel, use [enableLogging].
/// * To query channel enablement, use [shouldLog].
class LogManager {
  // Track initialization state to ensure no double VM service registrations.
  static bool _initialized = false;
  final Map<String, String?> _channelDescriptions = {};
  final Set<String> _enabledChannels = <String>{};
  final List<LogListener> _logListeners = <LogListener>[];
  final StreamController<String> _channelAddedBroadcaster =
      StreamController.broadcast();
  final StreamController<String> _channelEnabledBroadcaster =
      StreamController.broadcast();

  final LinkedHashSet<_ChannelInstallHandler> _channelInstallHandlers =
      LinkedHashSet<_ChannelInstallHandler>();

  @visibleForTesting
  LogManager() {
    _addChannelInstallHandler((name) {
      if (name == 'http') {
        installHttpChannel();
        return true;
      }
      return false;
    });
  }

  /// A map of channels to channel descriptions.
  Map<String, String?> get channelDescriptions => _channelDescriptions;

  void addListener(LogListener? listener) {
    if (listener != null && !_logListeners.contains(listener)) {
      _logListeners.add(listener);
    }
  }

  void enableLogging(String channel, {bool enable = true}) {
    enable ? _enabledChannels.add(channel) : _enabledChannels.remove(channel);
    _installHandlers(channel);
    _channelEnabledBroadcaster.add(channel);
  }

  /// Called to register service extensions.
  ///
  /// Note: ideally this will be replaced w/ inline registrations within the
  /// flutter foundation binding (see e.g., https://github.com/flutter/flutter/pull/21505).
  void initServiceExtensions() {
    // Avoid double initialization.
    if (_initialized == true) {
      return;
    }

    // Fire events for new channels.
    _channelAddedBroadcaster.stream.listen((String name) {
      developer.postEvent('logs.channel.added', <String, dynamic>{
        'channel': name,
      });
    });

    // Fire events for channel enablement changes.
    _channelEnabledBroadcaster.stream.listen((String name) {
      developer.postEvent('logs.channel.enabled', <String, dynamic>{
        'channel': name,
        'enabled': shouldLog(name),
      });
    });

    _registerServiceExtension(
      name: 'enable',
      callback: (Map<String, dynamic> parameters) async {
        final String? channel = parameters['channel'];
        if (channel != null) {
          if (parameters.containsKey('enabled')) {
            enableLogging(channel, enable: parameters['enabled'] == 'true');
          }
          return <String, dynamic>{
            'enabled': shouldLog(channel).toString(),
          };
        } else {
          return <String, dynamic>{};
        }
      },
    );

    _registerServiceExtension(
      name: 'loggingChannels',
      callback: (Map<String, dynamic> parameters) async => {
        'value': _channelDescriptions
            .map((channel, description) => MapEntry(channel, <String, String>{
                  'enabled': shouldLog(channel).toString(),
                  'description': description ?? '',
                }))
      },
    );

    _initialized = true;
  }

  void log(
    String channel,
    String message, {
    Map? data,
    ToJsonEncodable? toJsonEncodable,
    DateTime? time,
    int? level = 0,
    StackTrace? stackTrace,
  }) {
    var encodedData =
        data != null ? json.encode(data, toEncodable: toJsonEncodable) : null;
    for (var i = 0; i < _logListeners.length; ++i) {
      _logListeners[i](channel, message, encodedData, time, level, stackTrace);
    }
  }

  void registerChannel(String name, {String? description}) {
    if (_channelDescriptions.containsKey(name)) {
      throw LoggingException('a channel named "$name" is already registered');
    }
    _channelDescriptions[name] = description;

    _channelAddedBroadcaster.add(name);
  }

  void removeListener(LogListener? listener) {
    if (listener != null) {
      _logListeners.remove(listener);
    }
  }

  bool shouldLog(String channel) => _enabledChannels.contains(channel);

  void _addChannelInstallHandler(_ChannelInstallHandler handler) {
    _channelInstallHandlers.add(handler);
  }

  void _installHandlers(String name) {
    // Install and remove associated handler.
    _channelInstallHandlers.removeWhere((handler) => handler(name));
  }

  /// Registers a service extension method with the given name and a callback to
  /// be called when the extension method is called.
  void _registerServiceExtension({
    required String name,
    required _ServiceExtensionCallback callback,
  }) {
    final methodName = 'ext.flutter.logs.$name';
    developer.registerExtension(methodName,
        (String method, Map<String, String> parameters) async {
      assert(method == methodName);

      dynamic caughtException;
      late StackTrace caughtStack;
      var result = <String, dynamic>{};
      try {
        result = await callback(parameters);
      } catch (exception, stack) {
        caughtException = exception;
        caughtStack = stack;
      }
      if (caughtException == null) {
        result['type'] = '_extensionType';
        result['method'] = method;
        return developer.ServiceExtensionResponse.result(json.encode(result));
      } else {
        return developer.ServiceExtensionResponse.error(
            developer.ServiceExtensionResponse.extensionError,
            json.encode(<String, String>{
              'exception': caughtException.toString(),
              'stack': caughtStack.toString(),
              'method': method,
            }));
      }
    });
  }
}
