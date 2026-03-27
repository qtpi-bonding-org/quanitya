import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../infrastructure/config/debug_log.dart';
import 'package:injectable/injectable.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';

const _tag = 'logic/llm/services/local_llm_service';

/// Build-time URL for the model file.
const _modelDownloadUrl = String.fromEnvironment('MODEL_DOWNLOAD_URL');

/// Manages the on-device LLM for structured extraction.
///
/// Uses the llamadart backend directly (not LlamaEngine) so we can
/// keep the model loaded while creating a fresh context per generate()
/// call. This avoids stale KV cache / sampler state between extractions
/// without the overhead of reloading the model each time.
@lazySingleton
class LocalLlmService {
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

  /// Whether the model file exists on disk (downloaded previously).
  Future<bool> isModelDownloaded() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_modelFileName').existsSync();
  }

  /// Downloads the model file from the configured URL.
  ///
  /// [onProgress] is called with values from 0.0 to 1.0.
  /// Throws [StateError] if MODEL_DOWNLOAD_URL is not configured.
  Future<void> downloadModel({
    required void Function(double progress) onProgress,
  }) async {
    if (_modelDownloadUrl.isEmpty) {
      throw StateError(
        'MODEL_DOWNLOAD_URL not configured. '
        'Pass --dart-define=MODEL_DOWNLOAD_URL=<url> at build time.',
      );
    }

    final dir = await getApplicationSupportDirectory();
    final modelPath = '${dir.path}/$_modelFileName';
    final modelFile = File(modelPath);

    if (modelFile.existsSync()) {
      Log.d(_tag, '=== LocalLlmService: model already downloaded ===');
      onProgress(1.0);
      return;
    }

    Log.d(_tag, '=== LocalLlmService: downloading model from $_modelDownloadUrl ===');

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_modelDownloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw StateError(
          'Model download failed with status ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength;
      var bytesReceived = 0;

      final tmpFile = File('$modelPath.tmp');
      final sink = tmpFile.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0) {
          onProgress(bytesReceived / contentLength);
        }
      }

      await sink.flush();
      await sink.close();

      // Atomic rename — avoids partial file if download is interrupted
      await tmpFile.rename(modelPath);
      Log.d(_tag, '=== LocalLlmService: download complete ($bytesReceived bytes) ===');
    } finally {
      client.close();
    }
  }

  /// Loads the LLM model from disk.
  ///
  /// The model must have been downloaded first via [downloadModel].
  /// The model stays loaded across generate() calls — only the context
  /// is created/destroyed per call.
  ///
  /// Throws [TimeoutException] if loading exceeds 60 seconds.
  /// Throws [StateError] if the model is already loaded or not downloaded.
  Future<void> loadModel() async {
    if (_modelHandle != null) {
      throw StateError('Model is already loaded. Call unloadModel() first.');
    }

    Log.d(_tag, '=== LocalLlmService: starting model load ===');

    final dir = await getApplicationSupportDirectory();
    final modelPath = '${dir.path}/$_modelFileName';
    final modelFile = File(modelPath);

    if (!modelFile.existsSync()) {
      throw StateError(
        'Model file not found. Call downloadModel() first.',
      );
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
