import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabase {
  FakeSupabase(this.respond);

  http.Response? Function(http.Request request) respond;

  final requests = <http.Request>[];

  late final client = SupabaseClient(
    'https://example.supabase.co',
    'sb_publishable_test',
    authOptions: const AuthClientOptions(
      autoRefreshToken: false,
      authFlowType: AuthFlowType.implicit,
    ),
    httpClient: MockClient((request) async {
      requests.add(request);
      final response = respond(request) ?? json([]);
      return http.Response.bytes(
        response.bodyBytes,
        response.statusCode,
        headers: response.headers,
        request: request,
      );
    }),
  );

  static http.Response json(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}
