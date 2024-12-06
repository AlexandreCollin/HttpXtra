import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_xtra/src/extensions/map.dart';
import 'package:http_xtra/src/extensions/string.dart';

typedef Parser<T, ResponseBodyType> = T Function(ResponseBodyType value);
typedef Headers = Map<String, String>;
typedef Body = Map<String, dynamic>;

/// [baseUrl] will be the starting url of each requests so if [baseUrl] is
/// "https://my-url.com", and you use the [get] method with "/health" as
/// route, the endpoint will be "https://my-url.com/health"
///
/// Define [defaultHeaders] for it to be send with all fetching methods by
/// default
class HttpXtra {
  final String _baseUrl;
  final Headers _defaultHeaders;

  HttpXtra({
    required String baseUrl,
    Headers? defaultHeaders,
  })  : _baseUrl = baseUrl,
        _defaultHeaders = defaultHeaders ?? {};

  /// Replace existing default headers by [newHeaders]
  void setDefaultHeader(Headers newHeaders) {
    _defaultHeaders.clear();
    _defaultHeaders.addAll(newHeaders);
  }

  /// Add [newHeaders] to the default headers
  void addDefaultHeaders(Headers newHeaders) {
    _defaultHeaders.addAll(newHeaders);
  }

  /// Set the Authorization header with [token]. By default [isBearer] is true
  /// so header value will looks like : Bearer eyJhbGciOiJ...
  void setAuthorization(String token, {bool isBearer = true}) {
    _defaultHeaders['Authorization'] = "${isBearer ? "Bearer " : ""}$token";
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
    return http
        .get(
          "$_baseUrl$route".toUri(),
          headers: _defaultHeaders.merge(headers ?? {}),
        )
        .then((value) =>
            _parseResponse<ReturnValueType, ResponseBodyType>(value, parser));
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
    Body? body,
    Headers? headers,
  }) {
    if (headers == null || !headers.containsKey("Content-Type")) {
      headers = (headers ?? {}).merge({"Content-Type": "application/json"});
    }

    return http
        .post(
          "$_baseUrl$route".toUri(),
          body: body != null ? jsonEncode(body) : null,
          headers: _defaultHeaders.merge(headers),
        )
        .then((value) =>
            _parseResponse<ReturnValueType, BodyType>(value, parser));
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
    Body? body,
    Headers? headers,
  }) {
    if (headers == null || !headers.containsKey("Content-Type")) {
      headers = (headers ?? {}).merge({"Content-Type": "application/json"});
    }

    return http
        .put(
          "$_baseUrl$route".toUri(),
          body: body != null ? jsonEncode(body) : null,
          headers: _defaultHeaders.merge(headers),
        )
        .then((value) =>
            _parseResponse<ReturnValueType, ResponseBodyType>(value, parser));
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
    return http
        .delete(
          "$_baseUrl$route".toUri(),
          headers: _defaultHeaders.merge(headers ?? {}),
        )
        .then((value) =>
            _parseResponse<ReturnValueType, ResponseBodyType>(value, parser));
  }

  ReturnValueType _parseResponse<ReturnValueType, ResponseBodyType>(
    http.Response response,
    Parser<ReturnValueType, ResponseBodyType>? parser,
  ) {
    if (response.statusCode >= 400) {
      throw HttpException(utf8.decode(response.bodyBytes));
    }

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
