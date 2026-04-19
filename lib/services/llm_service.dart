import 'dart:async';
import 'package:llamadart/llamadart.dart';
import 'package:malo/services/display_info_service.dart';
import '../models/models.dart' hide ChatSession;

/// Wraps llamadart for on-device LLM inference.
class LlmService {
  static LlmService? _instance;
  LlmService._();
  static LlmService get instance => _instance ??= LlmService._();

  LlamaEngine? _engine;
  ChatSession? _session;

  bool _modelLoaded = false;
  LlmModel? _currentModel;

  bool get isModelLoaded => _modelLoaded && _engine != null;
  LlmModel? get currentModel => _currentModel;

  /// Load model - with caching to avoid reloads
  Future<void> loadModel(LlmModel model, String filePath) async {
    // ✅ FIXED: Check if same model is already loaded
    if (_modelLoaded && _currentModel?.id == model.id) {
      print('Model ${model.id} already loaded, skipping reload');
      return;
    }

    unloadModel(); // Clear any previous model

    try {
      // ✅ FIXED: Get device info for optimal settings
      final deviceInfo = await DeviceInfoService.instance.getDeviceInfo();
      final threads = (deviceInfo.ramGB >= 8) ? 6 : 4;
      final contextSize = (deviceInfo.ramGB >= 6) ? 4096 : 2048;

      _engine = LlamaEngine(LlamaBackend());

      await _engine!.loadModel(
        filePath,
        modelParams: ModelParams(
          contextSize: contextSize, // ✅ FIXED: Dynamic based on RAM
          numberOfThreads: threads, // ✅ FIXED: Dynamic based on CPU
          gpuLayers: 0, // Keep CPU-only for stability
        ),
      );

      _session = ChatSession(
        _engine!,
        systemPrompt: 'You are a helpful, concise, and accurate assistant running '
            'entirely on the user\'s device. Be friendly and keep responses clear.',
      );

      _currentModel = model;
      _modelLoaded = true;
      print('Model ${model.id} loaded successfully');
    } catch (e) {
      unloadModel();
      rethrow;
    }
  }

  /// Unload model and free memory
  void unloadModel() {
    _session = null;
    _engine?.dispose();
    _engine = null;
    _modelLoaded = false;
    _currentModel = null;
    print('Model unloaded, memory freed');
  }

  /// Stream tokens from user message
  Stream<String> sendMessage(String userMessage) async* {
    if (!_modelLoaded || _session == null || _engine == null) {
      yield "❌ No model is loaded. Please load a model first.";
      return;
    }

    try {
      await for (final chunk in _session!.create([
        LlamaTextContent(userMessage),
      ])) {
        final content = chunk.choices.firstOrNull?.delta?.content ?? '';
        if (content.isNotEmpty) {
          yield content;
        }
      }
    } catch (e) {
      yield "⚠️ Error during generation: $e";
    }
  }

  /// Clean up when the service is no longer needed
  Future<void> dispose() async {
    unloadModel();
  }
}
