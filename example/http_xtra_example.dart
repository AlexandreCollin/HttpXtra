import 'package:http_xtra/http_xtra.dart';

abstract class Api {
  static final HttpXtra client = HttpXtra(
    baseUrl: "https://my-base-url.com",
    onRefresh: (client, refreshToken) {
      if (refreshToken == null) return Future(() => null);
      return client.post<JsonBody, JsonBody>(
        "/refresh",
        body: {
          "refreshToken": refreshToken,
        },
      ).then(_setAuthorization);
    },
  );

  static Future<bool> isUp() => client.get<bool, String>(
        "/health",
        parser: (value) => value == "Up",
      );

  static Future<void> login(String email, String password) =>
      client.post<JsonBody, JsonBody>(
        "/login",
        body: {
          "email": email,
          "password": password,
        },
      ).then(_setAuthorization);

  static void _setAuthorization(JsonBody tokens) {
    client.setAuthorization(tokens['accessToken'],
        refreshToken: tokens['refreshToken']);
  }

  static Future<JsonBody> me() => client.get("/me");
}

void main() async {
  final bool isUp = await Api.isUp();

  if (isUp == false) return;

  await Api.login("my-email", "my-password");

  final Map<String, dynamic> me = await Api.me();

  print(me);
}
