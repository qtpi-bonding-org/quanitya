import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../infrastructure/config/debug_log.dart';
import 'package:injectable/injectable.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

const _tag = 'logic/llm/services/local_llm_service';

/// Manages the on-device LLM for structured extraction.
///
/// Uses the llamadart backend directly (not LlamaEngine) so we can
/// keep the model loaded while creating a fresh context per generate()
/// call. This avoids stale KV cache / sampler state between extractions
/// without the overhead of reloading the model each time.
@lazySingleton
class LocalLlmService {
  static const _modelAssetPath = 'assets/models/NuExtract-1.5-tiny-Q4_K_M.gguf';
  static const _modelFileName = 'NuExtract-1.5-tiny-Q4_K_M.gguf';
  static const _modelLoadTimeout = Duration(seconds: 60);
  static const _contextCreateTimeout = Duration(seconds: 10);
  static const _inferenceTimeout = Duration(seconds: 30);
  static const _modelParams = ModelParams(
    contextSize: 2048,
    gpuLayers: ModelParams.maxGpuLayers,
  );
  static const _maxTokens = 512;

  LlamaBackend? _backend;
  int? _modelHandle;

  /// Whether the model is loaded and ready for inference.
  bool get isReady => _modelHandle != null;

  /// Loads the LLM model from app assets.
  ///
  /// Copies the model file on first use, then loads it into the backend.
  /// The model stays loaded across generate() calls — only the context
  /// is created/destroyed per call.
  ///
  /// Throws [TimeoutException] if loading exceeds 60 seconds.
  /// Throws [StateError] if the model is already loaded.
  Future<void> loadModel() async {
    if (_modelHandle != null) {
      throw StateError('Model is already loaded. Call unloadModel() first.');
    }

    Log.d(_tag, '=== LocalLlmService: starting model load ===');

    // Copy model from assets to file system
    final dir = await getApplicationSupportDirectory();
    final modelPath = '${dir.path}/$_modelFileName';
    final modelFile = File(modelPath);

    if (!modelFile.existsSync()) {
      Log.d(_tag, '=== LocalLlmService: copying model from assets (469MB)... ===');
      final data = await rootBundle.load(_modelAssetPath);
      await modelFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      Log.d(_tag, '=== LocalLlmService: model copied ===');
    }

    final sw = Stopwatch()..start();
    final backend = LlamaBackend();
    final modelHandle = await backend
        .modelLoad(modelPath, _modelParams)
        .timeout(_modelLoadTimeout, onTimeout: () {
      throw TimeoutException(
        'Model loading timed out after ${_modelLoadTimeout.inSeconds}s.',
      );
    });
    sw.stop();

    Log.d(_tag, '=== LocalLlmService: model loaded in ${sw.elapsedMilliseconds}ms ===');

    _backend = backend;
    _modelHandle = modelHandle;
  }

  /// Runs inference with the given prompt and GBNF grammar constraint.
  ///
  /// Creates a fresh context for each call — no stale state between
  /// extractions. The model stays loaded (no reload overhead).
  ///
  /// [isCancelled] is polled between each generated token. Return `true`
  /// to stop inference early. Partial output up to cancellation is returned.
  ///
  /// Throws [StateError] if the model is not loaded.
  /// Throws [TimeoutException] if context creation exceeds 10s or
  /// inference exceeds 30s.
  Future<String> generate({
    required String prompt,
    required String grammar,
    bool Function()? isCancelled,
  }) async {
    if (_backend == null || _modelHandle == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    // Create fresh context for this extraction (with timeout for Metal alloc)
    final contextHandle = await _backend!
        .contextCreate(_modelHandle!, _modelParams)
        .timeout(_contextCreateTimeout, onTimeout: () {
      throw TimeoutException(
        'Context creation timed out after ${_contextCreateTimeout.inSeconds}s. '
        'Metal GPU allocation may have failed.',
      );
    });
    Log.d(_tag, '=== LocalLlmService: fresh context created, starting inference ===');

    try {
      final sw = Stopwatch()..start();
      final buffer = StringBuffer();
      final deadline = DateTime.now().add(_inferenceTimeout);

      final stream = _backend!.generate(
        contextHandle,
        prompt,
        GenerationParams(
          temp: 0.0,
          maxTokens: _maxTokens,
          grammar: grammar,
        ),
      );

      // Backend stream emits List<int> (UTF-8 bytes), decode to string
      await for (final bytes in stream) {
        if (isCancelled?.call() == true) {
          Log.d(_tag, '=== LocalLlmService: cancelled after ${sw.elapsedMilliseconds}ms ===');
          _backend!.cancelGeneration();
          sw.stop();
          return buffer.toString().trim();
        }

        if (DateTime.now().isAfter(deadline)) {
          Log.d(_tag, '=== LocalLlmService: timed out after ${_inferenceTimeout.inSeconds}s ===');
          _backend!.cancelGeneration();
          sw.stop();
          throw TimeoutException(
            'Inference timed out after ${_inferenceTimeout.inSeconds}s '
            '(${buffer.length} chars generated).',
          );
        }

        buffer.write(utf8.decode(bytes, allowMalformed: true));
      }

      sw.stop();
      Log.d(_tag, '=== LocalLlmService: done in ${sw.elapsedMilliseconds}ms, '
          '${buffer.length} chars ===');

      return buffer.toString().trim();
    } finally {
      // Always free the context — model stays loaded
      await _backend!.contextFree(contextHandle);
      Log.d(_tag, '=== LocalLlmService: context freed ===');
    }
  }

  /// Unloads the model and frees all resources.
  // TODO: Call explicitly before app exit / DI container reset —
  // the @disposeMethod is sync so it fire-and-forgets this Future.
  // In production, hook into app lifecycle to await this properly.
  Future<void> unloadModel() async {
    Log.d(_tag, '=== LocalLlmService: unloading ===');
    if (_modelHandle != null && _backend != null) {
      await _backend!.modelFree(_modelHandle!);
    }
    if (_backend != null) {
      await _backend!.dispose();
    }
    _modelHandle = null;
    _backend = null;
  }

  @disposeMethod
  void dispose() {
    unloadModel();
  }
}
