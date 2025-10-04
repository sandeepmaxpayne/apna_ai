import 'dart:async';
import 'dart:io';

import 'package:mistralai_dart/mistralai_dart.dart';

class ApiService {
  late final MistralAIClient _client;

  ApiService(String apiKey) {
    _client = MistralAIClient(apiKey: apiKey);
  }

  /// ------------------------------
  /// Non-streaming chat
  /// ------------------------------
  Future<String> sendQuery(String query) async {
    try {
      final res = await _client.createChatCompletion(
        request: ChatCompletionRequest(
          model: ChatCompletionModel.model(ChatCompletionModels.mistralMedium),
          temperature: 0,
          messages: [
            ChatCompletionMessage(
              role: ChatCompletionMessageRole.user,
              content: query,
            ),
          ],
        ),
      );

      return res.choices.first.message?.content ?? "No response";
    } catch (e) {
      return "Error: $e";
    }
  }

  /// ------------------------------
  /// Streaming chat
  /// ------------------------------
  Stream<String> streamQuery(String query) async* {
    try {
      final stream = _client.createChatCompletionStream(
        request: ChatCompletionRequest(
          model: ChatCompletionModel.model(ChatCompletionModels.mistralMedium),
          temperature: 0,
          messages: [
            ChatCompletionMessage(
              role: ChatCompletionMessageRole.user,
              content: query,
            ),
          ],
        ),
      );

      await for (final res in stream) {
        final delta = res.choices.first.delta.content;
        if (delta != null) yield delta;
      }
    } catch (e) {
      yield "(streaming unavailable: $e)";
    }
  }

  /// ------------------------------
  /// Image / Multimodal chat
  /// ------------------------------
  Future<String> uploadImage(String filePath, {String? query}) async {
    try {
      final bytes = await File(filePath).readAsBytes();

      final res = await _client.createChatCompletion(
        request: ChatCompletionRequest(
          model: const ChatCompletionModel.model(
              ChatCompletionModels.mistralMedium),
          temperature: 0,
          messages: [
            ChatCompletionMessage(
              role: ChatCompletionMessageRole.user,
              content: query ?? "Describe this image",
            ),
          ],
        ),
      );

      return res.choices.first.message?.content ?? "No response";
    } catch (e) {
      return "Image upload failed: $e";
    }
  }

  /// ------------------------------
  /// Create embeddings
  /// ------------------------------
  Future<List<double>> createEmbedding(String input) async {
    try {
      final res = await _client.createEmbedding(
        request: EmbeddingRequest(
          model: EmbeddingModel.model(EmbeddingModels.mistralEmbed),
          input: [input],
        ),
      );

      return res.data.first.embedding;
    } catch (e) {
      return [];
    }
  }

  /// ------------------------------
  /// List available models
  /// ------------------------------
  Future<List<String>> listModels() async {
    try {
      final res = await _client.listModels();
      return res.data.map((m) => m.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// ------------------------------
  /// End session
  /// ------------------------------
  void endSession() {
    _client.endSession();
  }
}
