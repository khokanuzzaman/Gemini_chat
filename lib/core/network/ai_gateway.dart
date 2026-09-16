// Feature: Core / Network
//
// Central AI gateway. Every AI datasource (chat, receipt, voice, prediction,
// budget) routes its HTTP calls through this class instead of hitting
// api.openai.com directly. The OpenAI key never ships inside the app — the
// backend at [API_BASE_URL] holds it server-side and mirrors OpenAI's HTTP
// contract, so request/response shapes stay identical.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Returns the app attestation / auth token attached to every AI request.
///
/// Placeholder for now — Task 1b wires this to Firebase App Check so the backend
/// can verify each request comes from a genuine build of this app. It must never
/// return an OpenAI key.
typedef AiAttestationTokenProvider = String Function();

/// Header that carries the app attestation token (Firebase App Check in Task 1b).
const String kAppAttestationHeader = 'X-App-Attestation';

/// Thrown when the app was built without an `API_BASE_URL`, so there is no
/// backend to route AI calls through. Surfaced as a clear error instead of
/// silently falling back to api.openai.com.
class AiBackendNotConfiguredException implements Exception {
  const AiBackendNotConfiguredException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'AiBackendNotConfiguredException';
}

/// Single HTTP client + endpoint resolver shared by every AI datasource.
///
/// The base URL comes from `--dart-define=API_BASE_URL=...` and defaults to an
/// empty string. When empty, [isConfigured] is false and the URI builders throw
/// [AiBackendNotConfiguredException].
class AiGateway {
  AiGateway({
    http.Client? client,
    String? baseUrl,
    AiAttestationTokenProvider? tokenProvider,
  }) : _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(baseUrl ?? _envBaseUrl),
       _tokenProvider = tokenProvider ?? _defaultTokenProvider;

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  // Placeholder attestation token, overridden by App Check wiring in Task 1b.
  static const String _envAttestationToken = String.fromEnvironment(
    'APP_ATTESTATION_TOKEN',
  );

  static String _defaultTokenProvider() => _envAttestationToken;

  /// OpenAI-compatible paths the backend mirrors 1:1.
  static const String chatCompletionsPath = '/v1/chat/completions';
  static const String transcriptionsPath = '/v1/audio/transcriptions';

  final http.Client _client;
  final String _baseUrl;
  final AiAttestationTokenProvider _tokenProvider;

  /// Whether an `API_BASE_URL` was provided at build time.
  bool get isConfigured => _baseUrl.isNotEmpty;

  /// Endpoint for chat/receipt/prediction/budget completions.
  Uri chatCompletionsUri() => _resolve(chatCompletionsPath);

  /// Endpoint for Whisper voice transcription.
  Uri transcriptionsUri() => _resolve(transcriptionsPath);

  /// Auth headers attached to every AI request. Carries the app attestation
  /// token — never an OpenAI key.
  Map<String, String> authHeaders() => {
    kAppAttestationHeader: _tokenProvider(),
  };

  /// Sends [request] through the shared HTTP client.
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _client.send(request);

  Uri _resolve(String path) {
    if (!isConfigured) {
      throw const AiBackendNotConfiguredException();
    }
    return Uri.parse('$_baseUrl$path');
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}

/// Shared, app-wide gateway instance so all AI datasources use one HTTP client.
final aiGatewayProvider = Provider<AiGateway>((ref) => AiGateway());
