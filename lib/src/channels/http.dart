import 'dart:async';
import 'dart:io';

import '../logs.dart';

final _HttpOverrides _httpOverrides = _HttpOverrides();

final Log _log = Log('http');

/// Hook to install the http channel.
void installHttpChannel() {
  if (!_log.enabled) {
    _log.enabled = true;
  }

  HttpOverrides.global = _httpOverrides;
}

Map<String, String> _headersToMap(HttpHeaders headers) {
  var map = <String, String>{};
  headers.forEach((String name, List<String> values) {
    map[name] = values.join(',');
  });
  return map;
}

void _todo(String msg) {
  print('todo: $msg');
}

class LoggingHttpClient implements HttpClient {
  late HttpClient proxy;

  @override
  String? userAgent;

  int _nextRequestId = 1;

  LoggingHttpClient({SecurityContext? context}) {
    HttpOverrides.global = null;
    proxy = HttpClient(context: context);
    HttpOverrides.global = _httpOverrides;
  }

  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String realm)? f) {
    _todo('authenticate');
    // proxy.authenticate = f;
  }

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String realm)?
        f,
  ) {
    _todo('authenticateProxy');
    // proxy.authenticateProxy = f;
  }

  @override
  bool get autoUncompress => proxy.autoUncompress;

  @override
  set autoUncompress(bool value) {
    proxy.autoUncompress = value;
  }

  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {
    _todo('badCertificateCallback');
    proxy.badCertificateCallback = callback;
  }

  @override
  Duration? get connectionTimeout => proxy.connectionTimeout;

  @override
  set connectionTimeout(Duration? connectionTimeout) {
    proxy.connectionTimeout = connectionTimeout;
  }

  @override
  set findProxy(String Function(Uri url)? f) {
    _todo('findProxy');
    proxy.findProxy = f;
  }

  @override
  Duration get idleTimeout => proxy.idleTimeout;

  @override
  set idleTimeout(Duration idleTimeout) {
    proxy.idleTimeout = idleTimeout;
  }

  @override
  int? get maxConnectionsPerHost => proxy.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? maxConnectionsPerHost) {
    proxy.maxConnectionsPerHost = maxConnectionsPerHost;
  }

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    _todo('addCredentials');
    proxy.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {
    _todo('addProxyCredentials');
    proxy.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  void close({bool force = false}) {
    // Not logged.
    proxy.close(force: force);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    _todo('delete');
    return proxy.delete(host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    _todo('deleteUrl');
    return proxy.deleteUrl(url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    // todo (pq): consider same logic as open (but w/ GET added)
    _todo('get');
    return proxy.get(host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    final id = _nextRequestId++;
    final method = 'GET';

    // #1 • GET https://flutter.io url
    _log.log('#$id • $method $url');

    var request = proxy.getUrl(url);
    return request.then((HttpClientRequest req) {
      _log.log('#$id • $method $url • request ready',
          data: _headersToMap(req.headers));

      req.done.then((HttpClientResponse response) {
        var len = response.contentLength >= 0
            ? ' ${response.contentLength} bytes'
            : '';
        _log.log(
          '#$id • $method $url • ${response.statusCode} ${response.reasonPhrase}$len',
          data: _headersToMap(response.headers),
        );
      });

      return req;
    });
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    _todo('head');
    return proxy.head(host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    _todo('headUrl');
    return proxy.headUrl(url);
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    _todo('open');
    return proxy.open(method, host, port, path);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    final id = _nextRequestId++;

    // #1 • GET https://flutter.io • open
    _log.log('#$id • $method $url • open');

    var request = proxy.openUrl(method, url);
    return request.then((HttpClientRequest req) {
      _log.log('#$id • $method $url • request ready');

      req.done.then((HttpClientResponse response) {
        var len = response.contentLength >= 0
            ? ' ${response.contentLength} bytes'
            : '';
        _log.log(
          '#$id • $method $url • ${response.statusCode} ${response.reasonPhrase}$len',
          data: _headersToMap(response.headers),
        );
      });

      return req;
    });
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    _todo('patch');
    return proxy.patch(host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    _todo('patchUrl');
    return proxy.patchUrl(url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    _todo('post');
    return proxy.post(host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    _todo('postUrl');
    return proxy.postUrl(url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    _todo('put');
    return proxy.put(host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    _todo('putUrl');
    return proxy.putUrl(url);
  }

  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {
    // TODO: implement connectionFactory
  }

  @override
  set keyLog(Function(String line)? callback) {
    // TODO: implement
  }
}

class _HttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      LoggingHttpClient(context: context);
}
