import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise.dart';
import '../models/pronunciation_result.dart';
import '../data/exercise_catalog.dart';
import '../data/ipa_dictionary.dart';
import '../services/audio_player_service.dart';
import '../services/tts_service.dart';
import '../services/pronunciation_service.dart';
import '../services/storage_service.dart';
import '../services/recording_service.dart';
import '../services/live_transcript_service.dart';
import '../services/openrouter_service.dart';
import '../services/phonetic_converter.dart';
import '../services/downloader/audio_downloader.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_visualizer.dart';
import 'feedback_dialog.dart';

class PracticeScreen extends StatefulWidget {
  final Exercise? initialExercise;
  final bool initialCustomMode;

  const PracticeScreen({
    super.key,
    this.initialExercise,
    this.initialCustomMode = false,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _audioPlayer = AudioPlayerService();
  final _tts = TtsService();
  final _pronunciationService = PronunciationService();
  final _storageService = StorageService();
  final _recordingService = RecordingService();
  final _liveTranscript = LiveTranscriptService();

  final _textController = TextEditingController();
  final _spokenInputController = TextEditingController();

  bool _isCustomMode = false;
  int _catalogIndex = 0;
  String _currentSentence = '';
  String _currentIpa = '';
  String _currentTranslation = '';
  String _currentFriendlyPhonetic = '';
  bool _showFriendlyPhonetic = true;
  String _currentTip = '';

  final _openRouter = OpenRouterService();
  bool _useOpenRouterTts = false;
  String _openRouterTtsModel = 'fish-audio/s2.1-pro:free';

  bool _isPlaying = false;
  double _playbackRate = 1.0;
  bool _isLooping = false;
  bool _isAssessing = false;
  String _accent = 'US';

  bool _isRecording = false;
  int _recordingSeconds = 0;
  RecordingResult? _lastRecording;
  String? _recordingError;
  Timer? _recordingTimer;

  StreamSubscription? _ttsSubscription;
  StreamSubscription? _ttsProgressSubscription;
  StreamSubscription? _playerCompleteSubscription;
  int? _activeCharStart;
  int? _activeCharEnd;
  bool _isPlayingRecording = false;

  @override
  void initState() {
    super.initState();

    _isCustomMode = widget.initialCustomMode ||
        (widget.initialExercise?.id.startsWith('custom-') ?? false);

    if (widget.initialExercise != null) {
      _loadExercise(widget.initialExercise!);
      if (_isCustomMode && widget.initialExercise!.phoneticIpa.isEmpty) {
        _fetchIpaForCustomText();
      }
    } else {
      _loadExercise(exerciseCatalog.first);
    }

    _ttsSubscription = _tts.onComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _activeCharStart = null;
          _activeCharEnd = null;
        });
        if (_isLooping) {
          _playReferenceAudio();
        }
      }
    });

    _ttsProgressSubscription = _tts.onProgress.listen((p) {
      if (mounted && _isPlaying) {
        setState(() {
          _activeCharStart = p.start;
          _activeCharEnd = p.end;
        });
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingRecording = false;
          _isPlaying = false;
          _activeCharStart = null;
          _activeCharEnd = null;
        });
        if (_isLooping) {
          _playReferenceAudio();
        }
      }
    });
  }

  void _loadExercise(Exercise ex) {
    setState(() {
      _currentSentence = ex.sentence;
      _currentIpa = ex.phoneticIpa;
      _currentTranslation = ex.translation;
      _currentFriendlyPhonetic = ex.friendlyPhonetic;
      _currentTip = ex.tip;
      _accent = ex.accent.isNotEmpty ? ex.accent : 'US';
      _textController.text = ex.sentence;
      _activeCharStart = null;
      _activeCharEnd = null;
      _isPlayingRecording = false;
    });
  }

  @override
  void dispose() {
    _ttsSubscription?.cancel();
    _ttsProgressSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _recordingTimer?.cancel();
    _audioPlayer.dispose();
    _tts.dispose();
    _recordingService.dispose();
    _liveTranscript.dispose();
    _textController.dispose();
    _spokenInputController.dispose();
    super.dispose();
  }

  void _playReferenceAudio() async {
    if (_isPlaying) {
      await _tts.stop();
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _activeCharStart = null;
        _activeCharEnd = null;
      });
      return;
    }

    await _audioPlayer.stop();
    setState(() {
      _isPlayingRecording = false;
      _isPlaying = true;
    });

    if (_useOpenRouterTts && _openRouter.isConfigured) {
      try {
        final audioBytes = await _openRouter.synthesizeSpeech(
          _currentSentence,
          model: _openRouterTtsModel,
        );
        if (audioBytes != null && audioBytes.isNotEmpty) {
          await _audioPlayer.playBytes(audioBytes, mimeType: 'audio/mpeg');
          return;
        }
      } catch (e) {
        debugPrint('OpenRouter TTS fallback: $e');
      }
    }

    // 2. Síntese Neural de Alta Fidelidade (via Backend - voz nativa cristalina)
    try {
      final audioBytes = await _pronunciationService.fetchTtsAudio(
        _currentSentence,
        accent: _accent,
        rate: _playbackRate,
      );
      if (audioBytes != null && audioBytes.isNotEmpty) {
        await _audioPlayer.playBytes(audioBytes, mimeType: 'audio/mpeg');
        return;
      }
    } catch (e) {
      debugPrint('Neural TTS fallback: $e');
    }

    // 3. Fallback para síntese nativa do sistema / Web Speech API
    await _tts.speak(
      _currentSentence,
      slow: _playbackRate < 0.9,
      lang: _accent == 'UK' ? 'en-GB' : 'en-US',
    );
  }

  void _toggleSpeed() {
    setState(() {
      _playbackRate = _playbackRate == 1.0 ? 0.75 : 1.0;
    });
    if (_isPlaying) {
      _playReferenceAudio();
    }
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
    });
  }

  void _onCustomTextChanged(String val) {
    final text = val.trim();
    setState(() {
      _currentSentence = val;
      if (text.isEmpty) {
        _currentIpa = '';
        _currentFriendlyPhonetic = '';
        _currentTranslation = '';
      } else {
        _currentFriendlyPhonetic = PhoneticConverter.textToFriendly(text);
        _currentTranslation = '';
      }
    });
  }

  Future<void> _fetchIpaForCustomText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _currentSentence = '';
        _currentIpa = '';
        _currentFriendlyPhonetic = '';
        _currentTranslation = '';
      });
      return;
    }

    setState(() {
      _currentSentence = text;
      _currentTranslation = '';
    });

    // Try backend G2P first
    final g2p = await _pronunciationService.getPhoneticsG2P(text);
    if (g2p != null && g2p['phoneticIpa'] != null) {
      final ipa = g2p['phoneticIpa'] as String;
      final friendlyFromBackend = (g2p['friendlyPhonetic'] as String?) ?? '';
      setState(() {
        _currentIpa = ipa;
        _currentFriendlyPhonetic = friendlyFromBackend.isNotEmpty
            ? friendlyFromBackend
            : PhoneticConverter.textToFriendly(text, ipaString: ipa);
      });
      return;
    }

    // Local dictionary and algorithmic converter fallback
    final words = text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final ipaParts = words.map((w) => ipaDictionary[w]?.ipa ?? '/$w/').toList();
    final ipaJoined = ipaParts.join(' ');
    setState(() {
      _currentIpa = ipaJoined;
      _currentFriendlyPhonetic = PhoneticConverter.textToFriendly(text, ipaString: ipaJoined);
    });
  }

  Future<void> _saveCurrentPhrase() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      await _storageService.saveCustomPhrase(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Frase salva na sua biblioteca!')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isAssessing) return;

    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _recordingTimer?.cancel();
      });
      final liveTranscript = await _liveTranscript.stop();
      final recording = await _recordingService.stop();

      if (recording == null) {
        setState(() {
          _recordingError =
              'Nenhum áudio foi capturado. Verifique o microfone e tente de novo.';
        });
        return;
      }

      setState(() => _lastRecording = recording);
      await _runAssessment(recording: recording, liveTranscript: liveTranscript);
    } else {
      setState(() {
        _recordingError = null;
        _lastRecording = null;
      });

      final started = await _recordingService.start();
      if (!started) {
        setState(() {
          _recordingError =
              'Não foi possível acessar o microfone. Verifique as permissões do dispositivo.';
        });
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });

      _liveTranscript.start();
    }
  }

  Future<void> _playRecordingPreview() async {
    final recording = _lastRecording;
    if (recording == null) return;
    await _tts.stop();
    setState(() {
      _isPlaying = false;
      _activeCharStart = null;
      _activeCharEnd = null;
    });

    if (_isPlayingRecording) {
      await _audioPlayer.stop();
      setState(() => _isPlayingRecording = false);
      return;
    }

    setState(() => _isPlayingRecording = true);

    if (kIsWeb && recording.path.startsWith('blob:')) {
      await _audioPlayer.playUrl(recording.path);
    } else {
      await _audioPlayer.playBytes(recording.bytes, mimeType: 'audio/wav');
    }
  }

  Future<void> _discardRecording() async {
    if (_isPlayingRecording) {
      await _audioPlayer.stop();
    }
    await _recordingService.cancel();
    setState(() {
      _lastRecording = null;
      _isPlayingRecording = false;
    });
  }

  Future<void> _downloadRecording() async {
    final recording = _lastRecording;
    if (recording == null || recording.bytes.isEmpty) return;

    final cleanName = _currentSentence
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final slug = cleanName.isEmpty
        ? 'gravacao'
        : (cleanName.length > 25 ? cleanName.substring(0, 25) : cleanName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'vocalis_${slug}_$timestamp.wav';

    try {
      final savedPath = await AudioDownloader.download(
        recording.bytes,
        filename: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? 'Download do áudio iniciado: $fileName'
                  : 'Áudio salvo em: ${savedPath ?? fileName}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao baixar gravação: $e',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  Future<void> _runAssessment({
    RecordingResult? recording,
    String? liveTranscript,
  }) async {
    if (_currentSentence.trim().isEmpty) return;

    setState(() {
      _isAssessing = true;
      _recordingError = null;
    });

    try {
      final typed = _spokenInputController.text.trim();
      final live = liveTranscript?.trim() ?? '';
      final userSpoken = typed.isNotEmpty
          ? typed
          : (live.isNotEmpty ? live : _currentSentence);

      // Run assessment
      final result = await _pronunciationService.assessAudio(
        audioBytes: recording?.bytes ?? const [0],
        referenceText: _currentSentence,
        spokenTranscript: userSpoken,
      );

      // Record to user history with weak words and phonemes for adaptive revision
      await _storageService.recordPracticeSession(
        result.overallScore,
        exerciseId:
            _isCustomMode ? 'custom' : exerciseCatalog[_catalogIndex].id,
        weakWords: result.words
            .where((w) => w.status == WordStatus.needsWork)
            .map((w) => w.word)
            .toList(),
        weakPhonemes: _isCustomMode
            ? const <String>[]
            : exerciseCatalog[_catalogIndex].keyPhonemes,
      );

      if (mounted) {
        FeedbackModal.show(
          context,
          result: result,
          tts: _tts,
          onRetry: () {
            _spokenInputController.clear();
          },
          onNext: !_isCustomMode && _catalogIndex + 1 < exerciseCatalog.length
              ? () {
                  setState(() {
                    _catalogIndex++;
                    _loadExercise(exerciseCatalog[_catalogIndex]);
                    _spokenInputController.clear();
                  });
                }
              : null,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssessing = false);
      }
    }
  }

  Widget _buildSentenceText() {
    if (_currentSentence.isEmpty) {
      return Text(
        'Digite uma frase acima...',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          height: 1.4,
        ),
      );
    }

    final start = _activeCharStart;
    final end = _activeCharEnd;
    final text = _currentSentence;

    if (_isPlaying &&
        start != null &&
        end != null &&
        start >= 0 &&
        end <= text.length &&
        start < end) {
      final before = text.substring(0, start);
      final active = text.substring(start, end);
      final after = text.substring(end);

      return RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            height: 1.4,
          ),
          children: [
            TextSpan(text: before),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  active,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
            TextSpan(text: after),
          ],
        ),
      );
    }

    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
        height: 1.4,
      ),
    );
  }

  void _showAiSettingsDialog() {
    final keyController = TextEditingController(text: _openRouter.apiKey);
    final backendController = TextEditingController(text: _pronunciationService.backendUrl);
    bool useOpenRouter = _useOpenRouterTts;
    String selectedModel = _openRouterTtsModel;
    bool isTestingAudio = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modelos de IA & OpenRouter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Síntese de voz e transcrição com modelos gratuitos',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chave de API do OpenRouter:',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: keyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'sk-or-v1-...',
                          prefixIcon: Icon(Icons.key, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Deixe em branco para usar o sintetizador gratuito local do navegador/dispositivo.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Servidor Backend Acústico / Neural (FastAPI):',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: backendController,
                        decoration: const InputDecoration(
                          hintText: 'http://192.168.1.22:8000',
                          prefixIcon: Icon(Icons.dns_outlined, size: 18),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'No smartphone via Wi-Fi, coloque o IP do seu computador (ex: http://192.168.1.22:8000).',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Ativar Síntese via OpenRouter (TTS)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Usa modelos neurais (ex: Fish Audio S2.1 Pro Free) em vez do TTS local.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                  value: useOpenRouter,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (val) {
                    setModalState(() => useOpenRouter = val);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Modelo TTS Selecionado:',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Fish Audio S2.1 (Free)'),
                      selected: selectedModel == 'fish-audio/s2.1-pro:free',
                      onSelected: (sel) {
                        if (sel) setModalState(() => selectedModel = 'fish-audio/s2.1-pro:free');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Deepgram Flux (Free)'),
                      selected: selectedModel == 'deepgram/flux:free',
                      onSelected: (sel) {
                        if (sel) setModalState(() => selectedModel = 'deepgram/flux:free');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: isTestingAudio
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.volume_up, size: 18),
                        label: const Text('Testar Áudio'),
                        onPressed: isTestingAudio
                            ? null
                            : () async {
                                final key = keyController.text.trim();
                                if (key.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Insira sua chave do OpenRouter para testar.'),
                                    ),
                                  );
                                  return;
                                }
                                setModalState(() => isTestingAudio = true);
                                await _openRouter.setApiKey(key);
                                final bytes = await _openRouter.synthesizeSpeech(
                                  'Hello! Welcome to Vocalis AI pronunciation practice.',
                                  model: selectedModel,
                                );
                                setModalState(() => isTestingAudio = false);

                                if (bytes != null && bytes.isNotEmpty) {
                                  await _audioPlayer.playBytes(bytes, mimeType: 'audio/mpeg');
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Não foi possível gerar áudio no OpenRouter. Verifique a chave e cota.'),
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Salvar'),
                        onPressed: () async {
                          await _openRouter.setApiKey(keyController.text.trim());
                          final newBackendUrl = backendController.text.trim();
                          if (newBackendUrl.isNotEmpty) {
                            await _pronunciationService.setBackendUrl(newBackendUrl);
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          setState(() {
                            _useOpenRouterTts = useOpenRouter;
                            _openRouterTtsModel = selectedModel;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Configurações salvas com sucesso!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final primaryFocus = FocusManager.instance.primaryFocus;
          if (primaryFocus != null && primaryFocus.context?.widget is EditableText) {
            return KeyEventResult.ignored;
          }

          if (event.logicalKey == LogicalKeyboardKey.space) {
            _toggleRecording();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyP) {
            _playReferenceAudio();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyR) {
            _playRecordingPreview();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isCustomMode ? 'Digitar & Treinar' : 'Treino Guiado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
            tooltip: 'Configurações de IA (OpenRouter)',
            onPressed: _showAiSettingsDialog,
          ),
          IconButton(
            icon: Icon(_isCustomMode ? Icons.library_books : Icons.edit_note),
            tooltip: _isCustomMode ? 'Ver Catálogo' : 'Digitar Frase Livre',
            onPressed: () {
              setState(() {
                _isCustomMode = !_isCustomMode;
                if (!_isCustomMode) {
                  _loadExercise(exerciseCatalog[_catalogIndex]);
                } else {
                  _currentTranslation = '';
                  if (_textController.text.trim().isNotEmpty) {
                    _currentSentence = _textController.text;
                    _currentFriendlyPhonetic = PhoneticConverter.textToFriendly(_textController.text);
                  }
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode toggle segmented control
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCustomMode = false;
                          _loadExercise(exerciseCatalog[_catalogIndex]);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isCustomMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !_isCustomMode
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Frases Sugeridas',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: !_isCustomMode ? AppTheme.primary : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCustomMode = true;
                          _currentTranslation = '';
                          if (_textController.text.trim().isNotEmpty) {
                            _currentSentence = _textController.text;
                            _currentFriendlyPhonetic = PhoneticConverter.textToFriendly(_textController.text);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isCustomMode ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _isCustomMode
                              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Digitar Minha Frase',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: _isCustomMode ? AppTheme.primary : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // If in Custom Mode: text input area
            if (_isCustomMode) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Digite a frase que deseja treinar:',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_add_outlined, color: AppTheme.primary),
                            tooltip: 'Salvar Frase',
                            onPressed: _saveCurrentPhrase,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Ex: Could you recommend a cozy coffee shop nearby?',
                        ),
                        onChanged: _onCustomTextChanged,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _fetchIpaForCustomText,
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Carregar Fonética & Pronúncia'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Target Sentence Display Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Catalog navigation arrows if in catalog mode
                    if (!_isCustomMode)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              exerciseCatalog[_catalogIndex].difficulty.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppTheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _catalogIndex > 0
                                    ? () {
                                        setState(() {
                                          _catalogIndex--;
                                          _loadExercise(exerciseCatalog[_catalogIndex]);
                                        });
                                      }
                                    : null,
                              ),
                              Text(
                                '${_catalogIndex + 1}/${exerciseCatalog.length}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _catalogIndex + 1 < exerciseCatalog.length
                                    ? () {
                                        setState(() {
                                          _catalogIndex++;
                                          _loadExercise(exerciseCatalog[_catalogIndex]);
                                        });
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 8),

                    // Sentence Text (com suporte a destaque karaoke em tempo real)
                    _buildSentenceText(),

                    // Tradução em Português do Brasil (pt-BR)
                    if (_currentTranslation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🇧🇷 ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Text(
                                _currentTranslation,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Bloco de Pronúncia: Abrasileirada (simplificada) e Alfabeto IPA
                    if (_currentFriendlyPhonetic.isNotEmpty || _currentIpa.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _showFriendlyPhonetic ? Icons.record_voice_over : Icons.translate,
                                      size: 16,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _showFriendlyPhonetic
                                          ? 'Pronúncia Abrasileirada'
                                          : 'Transcrição Fonética (IPA)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showFriendlyPhonetic = !_showFriendlyPhonetic;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _showFriendlyPhonetic ? 'Ver IPA' : 'Ver Abrasileirada',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.onPrimaryContainer,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.swap_horiz, size: 14, color: AppTheme.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _showFriendlyPhonetic
                                  ? (_currentFriendlyPhonetic.isNotEmpty ? _currentFriendlyPhonetic : _currentIpa)
                                  : _currentIpa,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _showFriendlyPhonetic ? const Color(0xFF0F172A) : AppTheme.primary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_currentTip.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _currentTip,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Audio Controls Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Play/Pause Reference Audio
                          ElevatedButton.icon(
                            onPressed: _currentSentence.isNotEmpty ? _playReferenceAudio : null,
                            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                            label: Text(_isPlaying ? 'Pausar' : 'Ouvir Áudio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),

                          Row(
                            children: [
                              // Speed button (0.75x or 1.0x)
                              TextButton(
                                onPressed: _toggleSpeed,
                                child: Text(
                                  '${_playbackRate}x',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _playbackRate < 1.0 ? AppTheme.warning : const Color(0xFF334155),
                                  ),
                                ),
                              ),

                              // Accent selector button (US or UK)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _accent = _accent == 'US' ? 'UK' : 'US';
                                  });
                                  if (_isPlaying) {
                                    _playReferenceAudio();
                                  }
                                },
                                child: Text(
                                  _accent == 'US' ? 'US 🇺🇸' : 'UK 🇬🇧',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),

                              // Loop button
                              IconButton(
                                icon: Icon(
                                  Icons.repeat,
                                  color: _isLooping ? AppTheme.primary : const Color(0xFF94A3B8),
                                ),
                                tooltip: 'Repetição contínua',
                                onPressed: _toggleLoop,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Compare / Recording Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sua Vez: Grave e Compare',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fale a frase no microfone ou digite o que você pronunciou para receber a pontuação e feedback fonético:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Microphone recording button
                    ElevatedButton.icon(
                      onPressed: _isAssessing ? null : _toggleRecording,
                      icon: _isRecording
                          ? const Icon(Icons.stop)
                          : const Icon(Icons.mic),
                      label: Text(
                        _isRecording ? 'Parar Gravação' : 'Pressione para Falar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRecording ? AppTheme.danger : AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    // Recording status
                    if (_isRecording) ...[
                      const SizedBox(height: 12),
                      WaveformVisualizer(
                        isRecording: _isRecording,
                        activeColor: AppTheme.danger,
                        height: 38,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Captando sua voz · ${_recordingSeconds}s',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Recorded audio chip
                    if (!_isRecording && _lastRecording != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.graphic_eq,
                                size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Gravação pronta · ${_lastRecording!.duration.inSeconds}s',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isPlayingRecording ? Icons.pause : Icons.play_arrow,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                              tooltip: _isPlayingRecording ? 'Pausar gravação' : 'Ouvir gravação',
                              onPressed: _playRecordingPreview,
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded,
                                  size: 20, color: AppTheme.primary),
                              tooltip: 'Baixar gravação (WAV)',
                              onPressed: _downloadRecording,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: AppTheme.danger),
                              tooltip: 'Descartar gravação',
                              onPressed: _discardRecording,
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Recording error
                    if (_recordingError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _recordingError!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.danger,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    TextField(
                      controller: _spokenInputController,
                      decoration: const InputDecoration(
                        hintText: 'O que você pronunciou (ou deixe vazio para testar)',
                        prefixIcon: Icon(Icons.mic_none),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      onPressed: _isAssessing ? null : _runAssessment,
                      icon: _isAssessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.assessment),
                      label: Text(
                        _isAssessing ? 'Avaliando Pronúncia...' : 'Comparar e Avaliar',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
