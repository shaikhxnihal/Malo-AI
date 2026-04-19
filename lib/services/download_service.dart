import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';
import '../models/models.dart';
import 'database_service.dart';

typedef ProgressCallback = void Function(
  int receivedBytes,
  int totalBytes,
  double speedMBs,
);

class DownloadService {
  static DownloadService? _instance;
  DownloadService._();
  static DownloadService get instance => _instance ??= DownloadService._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(hours: 3),
    followRedirects: true,
    maxRedirects: 5,
  ));

  CancelToken? _cancelToken;
  bool _isDownloading = false;
  
  // ✅ FIXED: Use BehaviorSubject for latest value + stream
  final _downloadStateController = BehaviorSubject<DownloadState?>.seeded(null);

  bool get isDownloading => _isDownloading;
  
  // ✅ Stream for UI to listen to download progress
  Stream<DownloadState?> get downloadStateStream => _downloadStateController.stream;
  
  // ✅ Get current download state
  DownloadState? get currentDownloadState => _downloadStateController.value;

  Future<String> _getModelPath(LlmModel model) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${dir.path}/models');
    if (!modelsDir.existsSync()) {
      await modelsDir.create(recursive: true);
    }
    return '${modelsDir.path}/${model.id}.gguf';
  }

  Future<bool> isDownloaded(String modelId) async {
    final ids = await DatabaseService.instance.getDownloadedModelIds();
    return ids.contains(modelId);
  }

  Future<String?> getModelPath(String modelId) async {
    return DatabaseService.instance.getModelFilePath(modelId);
  }

  Future<void> downloadModel({
    required LlmModel model,
    required ProgressCallback onProgress,
    required VoidCallback onComplete,
    required Function(String) onError,
  }) async {
    if (_isDownloading) {
      onError("Another download is already in progress.");
      return;
    }

    _isDownloading = true;
    _cancelToken = CancelToken();
    
    // ✅ Initialize download state
    final initialState = DownloadState(
      modelId: model.id,
      progress: 0,
      speedMbs: 0,
      receivedMB: 0,
      totalMB: model.sizeMB,
      isComplete: false,
      hasError: false,
      phase: 'Connecting...',
    );
    _downloadStateController.add(initialState);

    final savePath = await _getModelPath(model);
    final url = model.downloadUrl;

    final partialFile = File(savePath);
    if (partialFile.existsSync()) {
      await partialFile.delete();
    }

    int? lastReceived;
    DateTime? lastTime;

    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        deleteOnError: true,
        options: Options(
          receiveTimeout: const Duration(hours: 3),
        ),
        onReceiveProgress: (received, total) {
          final now = DateTime.now();
          double speedMBs = 0.0;

          if (lastReceived != null && lastTime != null) {
            final elapsed = now.difference(lastTime!).inMilliseconds / 1000.0;
            if (elapsed > 0.5) {
              final bytesPerSec = (received - lastReceived!) / elapsed;
              speedMBs = bytesPerSec / (1024 * 1024);
            }
          }

          lastReceived = received;
          lastTime = now;

          // ✅ Update global state
          final currentState = _downloadStateController.value;
          if (currentState != null) {
            final updatedState = currentState.copyWith(
              progress: total > 0 ? received / total : 0,
              speedMbs: speedMBs,
              receivedMB: (received / (1024 * 1024)).round(),
              totalMB: (total / (1024 * 1024)).round(),
              phase: _getPhase(total > 0 ? received / total : 0),
            );
            _downloadStateController.add(updatedState);
          }

          onProgress(received, total, speedMBs);
        },
      );

      await DatabaseService.instance.saveDownloadedModel(model, savePath);

      // ✅ Mark as complete - DON'T clear state yet, let UI handle it
      final currentState = _downloadStateController.value;
      if (currentState != null) {
        _downloadStateController.add(currentState.copyWith(
          isComplete: true,
          progress: 1.0,
          phase: 'Complete',
        ));
      }

      _isDownloading = false;
      onComplete();
      
      // ✅ Clear state after a delay to let UI update
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDownloading) {
          _downloadStateController.add(null);
        }
      });
    } on DioException catch (e) {
      _isDownloading = false;

      if (e.type == DioExceptionType.cancel) {
        final f = File(savePath);
        if (f.existsSync()) await f.delete();
        
        // ✅ Mark as cancelled
        final currentState = _downloadStateController.value;
        if (currentState != null) {
          _downloadStateController.add(currentState.copyWith(
            hasError: true,
            errorMsg: 'Download cancelled',
            phase: 'Cancelled',
          ));
        }
        
        print("Download cancelled by user");
      } else {
        // ✅ Mark as error
        final currentState = _downloadStateController.value;
        if (currentState != null) {
          _downloadStateController.add(currentState.copyWith(
            hasError: true,
            errorMsg: e.message ?? 'Unknown error',
            phase: 'Failed',
          ));
        }
        
        print("Dio Download Error: ${e.message} | ${e.response?.statusCode}");
        onError(e.message ?? e.toString());
      }
      
      // ✅ Clear state after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDownloading) {
          _downloadStateController.add(null);
        }
      });
    } catch (e, stack) {
      _isDownloading = false;
      
      // ✅ Mark as error
      final currentState = _downloadStateController.value;
      if (currentState != null) {
        _downloadStateController.add(currentState.copyWith(
          hasError: true,
          errorMsg: e.toString(),
          phase: 'Failed',
        ));
      }
      
      print("Unexpected Download Error: $e\n$stack");
      onError(e.toString());
      
      // ✅ Clear state after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isDownloading) {
          _downloadStateController.add(null);
        }
      });
    }
  }

  String _getPhase(double progress) {
    if (progress < 0.08) return 'Connecting...';
    if (progress < 0.95) return 'Downloading...';
    return 'Finalizing...';
  }

  void cancelDownload() {
    _cancelToken?.cancel("User cancelled download");
    _cancelToken = null;
    _isDownloading = false;
  }

  // ✅ FIXED: Don't clear state immediately, let it persist for UI
  void clearDownloadState() {
    // Only clear if not actively downloading
    if (!_isDownloading) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _downloadStateController.add(null);
      });
    }
  }

  // ✅ ADDED: Proper dispose
  void dispose() {
    _downloadStateController.close();
  }

  Future<void> deleteModel(LlmModel model) async {
    final path = await getModelPath(model.id);
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    await DatabaseService.instance.deleteDownloadedModel(model.id);
  }
}
