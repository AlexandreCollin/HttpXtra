import 'package:http_xtra/http_xtra.dart';

abstract class Api {
  static final HttpXtra client = HttpXtra(baseUrl: "https://my-endpoint.com");

  static Future<bool> isUp() => client.get<bool, String>(
        "/health",
        parser: (value) => value == "Up",
      );

  static Future<void> login() =>
      client.post<Map<String, dynamic>, Map<String, dynamic>>(
        "/login",
        body: {
          "email": "my-email",
          "password": "my-password",
        },
      ).then((tokens) => client.setAuthorization(tokens['accessToken']));

  static Future<Map<String, dynamic>> me() => client.get("/me");
}

void main() async {
  final bool isUp = await Api.isUp();

  if (isUp == false) return;

  await Api.login();

  final Map<String, dynamic> me = await Api.me();

  print(me);
}
