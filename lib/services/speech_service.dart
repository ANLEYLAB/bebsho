import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

class GlobalSpeechEngine {
  static final GlobalSpeechEngine _instance = GlobalSpeechEngine._internal();
  factory GlobalSpeechEngine() => _instance;
  GlobalSpeechEngine._internal();

  VoskFlutterPlugin? _vosk;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  bool _isInitialized = false;
  bool _isInitializing = false;

  bool get isInitialized => _isInitialized;

  final StreamController<String> _partialController = StreamController<String>.broadcast();
  final StreamController<String> _resultController = StreamController<String>.broadcast();
  StreamSubscription<String>? _rawPartialSub;
  StreamSubscription<String>? _rawResultSub;

  Stream<String> get onPartialResult => _partialController.stream;
  Stream<String> get onResult => _resultController.stream;

  Future<void> init() async {
    if (_isInitialized || _isInitializing || kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    _isInitializing = true;

    try {
      print("Vosk: Starting init...");
      _vosk = VoskFlutterPlugin.instance();
      String path = await ModelLoader().loadFromAssets('assets/models/vosk-model-small-en-us-0.15.zip');
      print("Vosk: Model asset loaded to path: $path");

      final dir = Directory(path);
      if (await dir.exists()) {
        final subDirs = dir.listSync().whereType<Directory>().toList();
        if (subDirs.length == 1 && !File('$path/am/final.mdl').existsSync()) {
          path = subDirs.first.path;
          print("Vosk: Adjusted path to subDir: $path");
        }
      }

      print("Vosk: Creating model...");
      _model = await _vosk!.createModel(path);
      print("Vosk: Creating recognizer...");
      _recognizer = await _vosk!.createRecognizer(model: _model!, sampleRate: 16000);
      print("Vosk: Initializing SpeechService...");
      _speechService = await _vosk!.initSpeechService(_recognizer!);

      _rawPartialSub?.cancel();
      _rawPartialSub = _speechService?.onPartial().listen((json) {
        try {
          final data = jsonDecode(json);
          final partial = (data['partial'] as String? ?? "").trim();
          if (partial.isNotEmpty) {
            print("Vosk >> Partial detected: $partial");
            _partialController.add(partial);
          }
        } catch (e) {
          print("Vosk onPartial error: $e");
        }
      });

      _rawResultSub?.cancel();
      _rawResultSub = _speechService?.onResult().listen((json) {
        try {
          final data = jsonDecode(json);
          final text = (data['text'] as String? ?? "").trim();
          if (text.isNotEmpty) {
            print("Vosk >> Result detected: $text");
            _resultController.add(text);
          }
        } catch (e) {
          print("Vosk onResult error: $e");
        }
      });

      _isInitialized = true;
      print("Vosk: Engine initialized successfully!");
    } catch (e, stack) {
      print("Vosk engine init error: $e\n$stack");
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> start() async {
    print("Vosk: start() called. isInitialized=$_isInitialized, service=$_speechService");
    if (!_isInitialized || _speechService == null) return;
    try {
      final res = await _speechService?.start();
      print("Vosk: start() result: $res");
    } catch (e, stack) {
      print("Vosk start error: $e\n$stack");
    }
  }

  Future<void> stop() async {
    print("Vosk: stop() called. isInitialized=$_isInitialized, service=$_speechService");
    if (!_isInitialized || _speechService == null) return;
    try {
      final res = await _speechService?.stop();
      print("Vosk: stop() result: $res");
    } catch (e, stack) {
      print("Vosk stop error: $e\n$stack");
    }
  }
}
