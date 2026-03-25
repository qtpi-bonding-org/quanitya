import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Manages the on-device LLM engine for structured extraction.
///
/// Each [generate] call creates a fresh engine+context to avoid
/// stale state between extractions. The model file is cached on disk
/// so reloads are fast (~400ms with Metal/OS caching).
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

  String? _modelPath;

  /// Whether the model file is ready (copied to app support dir).
  bool get isReady => _modelPath != null;

  /// Prepares the model file for use.
  ///
  /// Copies the model from Flutter assets to the app support directory
  /// on first call. Subsequent calls are a no-op (file already exists).
  ///
  /// Throws [TimeoutException] if the initial copy takes too long.
  /// Throws [StateError] if already prepared.
  Future<void> loadModel() async {
    if (_modelPath != null) {
      throw StateError('Model already prepared. Path: $_modelPath');
    }

    debugPrint('=== LocalLlmService: preparing model ===');

    final dir = await getApplicationSupportDirectory();
    final modelPath = '${dir.path}/$_modelFileName';
    final modelFile = File(modelPath);

    if (!modelFile.existsSync()) {
      debugPrint('=== LocalLlmService: copying model from assets (469MB)... ===');
      final data = await rootBundle.load(_modelAssetPath);
      await modelFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      debugPrint('=== LocalLlmService: model copied ===');
    }

    // Verify the model loads correctly by doing a test load
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
    await engine.dispose();
    sw.stop();

    debugPrint('=== LocalLlmService: model verified in ${sw.elapsedMilliseconds}ms ===');
    _modelPath = modelPath;
  }

  /// Runs inference with the given prompt and GBNF grammar constraint.
  ///
  /// Creates a fresh engine+context per call to guarantee clean state.
  /// The model file is on disk and Metal weights are OS-cached, so
  /// reload overhead is ~400ms.
  ///
  /// [isCancelled] is polled between each generated token. Return `true`
  /// to stop inference early. Partial output up to cancellation is returned.
  ///
  /// Throws [StateError] if the model is not prepared.
  /// Throws [TimeoutException] if inference exceeds 30 seconds.
  Future<String> generate({
    required String prompt,
    required String grammar,
    bool Function()? isCancelled,
  }) async {
    if (_modelPath == null) {
      throw StateError('Model not prepared. Call loadModel() first.');
    }

    debugPrint('=== LocalLlmService: loading fresh engine ===');

    // Fresh engine per call — guarantees no stale context/sampler state.
    final engine = LlamaEngine(LlamaBackend());
    try {
      await engine.loadModel(
        _modelPath!,
        modelParams: const ModelParams(
          contextSize: _contextSize,
          gpuLayers: ModelParams.maxGpuLayers,
        ),
      );

      debugPrint('=== LocalLlmService: starting inference ===');

      final sw = Stopwatch()..start();
      final buffer = StringBuffer();
      final deadline = DateTime.now().add(_inferenceTimeout);

      await for (final token in engine.generate(
        prompt,
        params: GenerationParams(
          temp: 0.0,
          maxTokens: _maxTokens,
          grammar: grammar,
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
    } finally {
      await engine.dispose();
    }
  }

  /// Resets the service state.
  void unloadModel() {
    debugPrint('=== LocalLlmService: unloading ===');
    _modelPath = null;
  }

  /// Disposes all resources.
  @disposeMethod
  void dispose() {
    unloadModel();
  }
}
