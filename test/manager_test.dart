import 'package:logs/src/log_manager.dart';
import 'package:test/test.dart';

void main() {
  group('manager tests', () {
    late LogManager manager;
    late String loggedMessage;
    late String loggedChannel;
    Object? loggedData;
    DateTime? loggedTime;
    int? loggedLevel;
    StackTrace? loggedStackTrace;

    setUp(() {
      manager = LogManager()
        ..addListener((channel, message, data, time, level, stackTrace) {
          loggedMessage = message;
          loggedChannel = channel;
          loggedData = data;
          loggedTime = time;
          loggedLevel = level;
          loggedStackTrace = stackTrace;
        });
    });

    test('register', () {
      expect(manager.channelDescriptions.containsKey('foo'), isFalse);
      manager.registerChannel('foo');
      expect(manager.channelDescriptions.containsKey('foo'), isTrue);
    });

    test('register twice', () {
      expect(manager.channelDescriptions.containsKey('foo'), isFalse);
      manager.registerChannel('foo');
      expect(manager.channelDescriptions.containsKey('foo'), isTrue);
      expect(() => manager.registerChannel('foo'), throwsException);
    });

    test('enable', () {
      manager.registerChannel('foo');
      expect(manager.shouldLog('foo'), isFalse);
      manager.enableLogging('foo');
      expect(manager.shouldLog('foo'), isTrue);
    });

    test('enable (unregistered)', () {
      expect(manager.shouldLog('foo'), isFalse);
      // should *not* throw an exception
      manager.enableLogging('foo');
      manager.registerChannel('foo');
      expect(manager.shouldLog('foo'), isTrue);
    });

    test('disable', () {
      manager.registerChannel('foo');
      expect(manager.shouldLog('foo'), isFalse);
      manager.enableLogging('foo');
      expect(manager.shouldLog('foo'), isTrue);
      manager.enableLogging('foo', enable: false);
      expect(manager.shouldLog('foo'), isFalse);
    });

    test('description', () {
      manager.registerChannel('foo', description: 'a channel for foos');
      expect(manager.channelDescriptions['foo'], 'a channel for foos');
    });

    test('channels', () {
      manager.registerChannel('foo');
      manager.registerChannel('bar');
      manager.registerChannel('baz');
      expect(
          manager.channelDescriptions.keys, containsAll(['foo', 'bar', 'baz']));
    });

    test('log', () {
      manager.registerChannel('foo');
      manager.enableLogging('foo');
      final testTrace = StackTrace.fromString('test trace');
      final time = DateTime.now();
      manager.log(
        'foo',
        'bar',
        data: {
          'x': 1,
          'y': 2,
          'z': 3,
        },
        level: 200,
        time: time,
        stackTrace: testTrace,
      );
      expect(loggedMessage, 'bar');
      expect(loggedChannel, 'foo');
      expect(loggedData, '{"x":1,"y":2,"z":3}');
      expect(loggedLevel, 200);
      expect(loggedTime, time);
      expect(loggedStackTrace, testTrace);
    });
  });
}
