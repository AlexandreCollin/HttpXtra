import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_xtra/src/extensions/map.dart';
import 'package:http_xtra/src/extensions/string.dart';

typedef Parser<T, ResponseBodyType> = T Function(ResponseBodyType value);
typedef Headers = Map<String, String>;
typedef JsonBody = Map<String, dynamic>;
typedef RefreshRequest = Future<void> Function(
    HttpXtra client, String? refreshToken);

/// [baseUrl] will be the starting url of each requests so if [baseUrl] is
/// "https://my-url.com", and you use the [get] method with "/health" as
/// route, the endpoint will be "https://my-url.com/health"
///
/// Define [defaultHeaders] for it to be send with all fetching methods by
/// default
///
/// If you want to refresh the access token when it is expired, you can
/// provide a [onRefresh] function that will be called when the server
/// returns a 401 status code. This function will be called with the
/// [HttpXtra] instance as parameter. You can use this instance to
/// set the new access token using the [setAuthorization] method.
class HttpXtra {
  final String _baseUrl;
  final Headers _defaultHeaders;

  bool _isRefreshing = false;
  final RefreshRequest? _onRefresh;
  String? _refreshToken;

  HttpXtra({
    required String baseUrl,
    Headers? defaultHeaders,
    RefreshRequest? onRefresh,
  })  : _baseUrl = baseUrl,
        _defaultHeaders = defaultHeaders ?? {},
        _onRefresh = onRefresh;

  /// Replace existing default headers by [newHeaders]
  void setDefaultHeader(Headers newHeaders) {
    _defaultHeaders.clear();
    _defaultHeaders.addAll(newHeaders);
  }

  /// Add [newHeaders] to the default headers
  void addDefaultHeaders(Headers newHeaders) {
    _defaultHeaders.addAll(newHeaders);
  }

  /// Set the Authorization header with [accessToken]. By default [isBearer] is true
  /// so header value will looks like : Bearer eyJhbGciOiJ...
  void setAuthorization(String accessToken,
      {String? refreshToken, bool isBearer = true}) {
    _defaultHeaders['Authorization'] =
        "${isBearer ? "Bearer " : ""}$accessToken";
    _refreshToken = refreshToken;
  }

  /// Fetch data usig GET method
  ///
  /// Use [route] to define the endpoint
  ///
  /// If [parser] is provided, the response body of type [ResponseBodyType]
  /// will be parsed to return a value of type [ReturnValueType]
  ///
  /// If [headers] is provided, it will be merged with the default headers
  Future<ReturnValueType> get<ReturnValueType, ResponseBodyType>(
    String route, {
    Parser<ReturnValueType, ResponseBodyType>? parser,
    Headers? headers,
  }) {
    return _sendRequest(
      "GET",
      route,
      headers: headers,
      parser: parser,
    );
  }

  /// Fetch data usig POST method
  ///
  /// Use [route] to define the endpoint
  ///
  /// If [parser] is provided, the response body of type [ResponseBodyType]
  /// will be parsed to return a value of type [ReturnValueType]
  ///
  /// If [body] is provided, it will be send as a json in the request
  ///
  /// If [headers] is provided, it will be merged with the default headers
  Future<ReturnValueType> post<ReturnValueType, BodyType>(
    String route, {
    Parser<ReturnValueType, BodyType>? parser,
    JsonBody? body,
    Headers? headers,
  }) {
    return _sendRequest(
      "POST",
      route,
      headers: headers,
      body: body,
      parser: parser,
    );
  }

  /// Fetch data usig PUT method
  ///
  /// Use [route] to define the endpoint
  ///
  /// If [parser] is provided, the response body of type [ResponseBodyType]
  /// will be parsed to return a value of type [ReturnValueType]
  ///
  /// If [body] is provided, it will be send as a json in the request
  ///
  /// If [headers] is provided, it will be merged with the default headers
  Future<ReturnValueType> put<ReturnValueType, ResponseBodyType>(
    String route, {
    Parser<ReturnValueType, ResponseBodyType>? parser,
    JsonBody? body,
    Headers? headers,
  }) {
    return _sendRequest(
      "PUT",
      route,
      headers: headers,
      body: body,
      parser: parser,
    );
  }

  /// Fetch data usig PATCH method
  ///
  /// Use [route] to define the endpoint
  ///
  /// If [parser] is provided, the response body of type [ResponseBodyType]
  /// will be parsed to return a value of type [ReturnValueType]
  ///
  /// If [body] is provided, it will be send as a json in the request
  ///
  /// If [headers] is provided, it will be merged with the default headers
  Future<ReturnValueType> patch<ReturnValueType, ResponseBodyType>(
    String route, {
    Parser<ReturnValueType, ResponseBodyType>? parser,
    JsonBody? body,
    Headers? headers,
  }) {
    return _sendRequest(
      "PATCH",
      route,
      headers: headers,
      body: body,
      parser: parser,
    );
  }

  /// Fetch data usig HEAD method
  ///
  /// Use [route] to define the endpoint
  ///
  /// If [parser] is provided, the response body of type [ResponseBodyType]
  /// will be parsed to return a value of type [ReturnValueType]
  ///
  /// If [headers] is provided, it will be merged with the default headers
  Future<ReturnValueType> head<ReturnValueType, ResponseBodyType>(
    String route, {
    Parser<ReturnValueType, ResponseBodyType>? parser,
    Headers? headers,
  }) {
    return _sendRequest(
      "HEAD",
      route,
      headers: headers,
      parser: parser,
    );
  }

  /// Fetch data usig DELETE method
  ///
  /// Use [route] to define the endpoint
  ///
  /// If [parser] is provided, the response body of type [ResponseBodyType]
  /// will be parsed to return a value of type [ReturnValueType]
  ///
  /// If [headers] is provided, it will be merged with the default headers
  Future<ReturnValueType> delete<ReturnValueType, ResponseBodyType>(
    String route, {
    Parser<ReturnValueType, ResponseBodyType>? parser,
    Headers? headers,
  }) {
    return _sendRequest("DELETE", route, headers: headers, parser: parser);
  }

  Future<ReturnValueType> _sendRequest<ReturnValueType, ResponseBodyType>(
    String method,
    String route, {
    Headers? headers,
    JsonBody? body,
    Parser<ReturnValueType, ResponseBodyType>? parser,
  }) async {
    final http.Request request =
        http.Request(method, "$_baseUrl$route".toUri());

    request.headers.addAll(_defaultHeaders.merge(headers ?? {}));
    if (body != null) {
      request.body = jsonEncode(body);
      request.headers["Content-Type"] = "application/json";
    }

    return http.Response.fromStream(await request.send())
        .then((response) async {
      if (response.statusCode == HttpStatus.unauthorized &&
          _onRefresh != null &&
          !_isRefreshing) {
        _isRefreshing = true;
        await _onRefresh(this, _refreshToken);
        return await _sendRequest(
          method,
          route,
          headers: headers,
          body: body,
          parser: parser,
        ).whenComplete(() => _isRefreshing = false);
      }
      if (response.statusCode >= 400) {
        throw HttpException(utf8.decode(response.bodyBytes));
      }

      return _parseResponse<ReturnValueType, ResponseBodyType>(
          response, parser);
    });
  }

  ReturnValueType _parseResponse<ReturnValueType, ResponseBodyType>(
    http.Response response,
    Parser<ReturnValueType, ResponseBodyType>? parser,
  ) {
    try {
      final ResponseBodyType body = jsonDecode(utf8.decode(response.bodyBytes));

      return parser != null ? parser(body) : body as ReturnValueType;
    } on Exception {
      return parser != null
          ? parser(response.body as ResponseBodyType)
          : response.body as ReturnValueType;
    }
  }
}
