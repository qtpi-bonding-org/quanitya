import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Manages the on-device LLM engine for structured extraction.
///
/// Handles model lifecycle (load/unload), inference with timeout
/// and cancellation support. The model is loaded once and reused
/// for multiple extractions.
///
/// Uses llamadart (llama.cpp Dart bindings) with Metal GPU
/// acceleration on iOS physical devices.
@lazySingleton
class LocalLlmService {
  static const _modelAssetPath = 'assets/models/NuExtract-1.5-tiny-Q4_K_M.gguf';
  static const _modelFileName = 'NuExtract-1.5-tiny-Q4_K_M.gguf';
  static const _modelLoadTimeout = Duration(seconds: 60);
  static const _inferenceTimeout = Duration(seconds: 30);
  static const _contextSize = 2048;
  static const _maxTokens = 512;

  LlamaEngine? _engine;

  /// Whether the model is loaded and ready for inference.
  bool get isReady => _engine != null;

  /// Loads the LLM model from app assets.
  ///
  /// On first call, copies the model file (469MB) from Flutter assets
  /// to the app support directory. Subsequent calls use the cached copy.
  ///
  /// Throws [TimeoutException] if loading exceeds 60 seconds.
  /// Throws [StateError] if the model is already loaded.
  Future<void> loadModel() async {
    if (_engine != null) {
      throw StateError('Model is already loaded. Call unloadModel() first.');
    }

    debugPrint('=== LocalLlmService: starting model load ===');

    final dir = await getApplicationSupportDirectory();
    final modelPath = '${dir.path}/$_modelFileName';
    final modelFile = File(modelPath);

    if (!modelFile.existsSync()) {
      debugPrint('=== LocalLlmService: copying model from assets (469MB)... ===');
      final data = await rootBundle.load(_modelAssetPath);
      await modelFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      debugPrint('=== LocalLlmService: model copied ===');
    }

    final sw = Stopwatch()..start();
    final engine = LlamaEngine(LlamaBackend());

    await engine
        .loadModel(
          modelPath,
          modelParams: const ModelParams(
            contextSize: _contextSize,
            gpuLayers: ModelParams.maxGpuLayers,
          ),
        )
        .timeout(_modelLoadTimeout, onTimeout: () {
      throw TimeoutException(
        'Model loading timed out after ${_modelLoadTimeout.inSeconds}s. '
        'On-device inference may not be supported on this device.',
      );
    });

    sw.stop();
    debugPrint('=== LocalLlmService: model loaded in ${sw.elapsedMilliseconds}ms ===');

    _engine = engine;
  }

  /// Runs inference with the given prompt and GBNF grammar constraint.
  ///
  /// Returns the raw output string (typically JSON when grammar-constrained).
  ///
  /// [isCancelled] is polled between each generated token. Return `true`
  /// to stop inference early. Partial output up to cancellation is returned.
  ///
  /// Throws [StateError] if the model is not loaded.
  /// Throws [TimeoutException] if inference exceeds 30 seconds.
  Future<String> generate({
    required String prompt,
    required String grammar,
    bool Function()? isCancelled,
  }) async {
    if (_engine == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    debugPrint('=== LocalLlmService: starting inference ===');

    final sw = Stopwatch()..start();
    final buffer = StringBuffer();
    final deadline = DateTime.now().add(_inferenceTimeout);

    await for (final token in _engine!.generate(
      prompt,
      params: GenerationParams(
        temp: 0.0,
        maxTokens: _maxTokens,
        grammar: grammar,
        reusePromptPrefix: false, // 1-shot extraction, clear context each call
      ),
    )) {
      if (isCancelled?.call() == true) {
        debugPrint('=== LocalLlmService: cancelled after ${sw.elapsedMilliseconds}ms ===');
        sw.stop();
        return buffer.toString().trim();
      }

      if (DateTime.now().isAfter(deadline)) {
        debugPrint('=== LocalLlmService: timed out after ${_inferenceTimeout.inSeconds}s ===');
        sw.stop();
        throw TimeoutException(
          'Inference timed out after ${_inferenceTimeout.inSeconds}s '
          '(${buffer.length} chars generated). '
          'On-device inference may be too slow for this device.',
        );
      }

      buffer.write(token);
    }

    sw.stop();
    debugPrint('=== LocalLlmService: done in ${sw.elapsedMilliseconds}ms, '
        '${buffer.length} chars ===');

    return buffer.toString().trim();
  }

  /// Unloads the model and frees memory.
  void unloadModel() {
    debugPrint('=== LocalLlmService: unloading model ===');
    _engine?.dispose();
    _engine = null;
  }

  /// Disposes all resources.
  @disposeMethod
  void dispose() {
    unloadModel();
  }
}
