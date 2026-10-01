import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/dialogue_scenarios.dart';
import '../models/dialogue.dart';
import '../services/live_transcript_service.dart';
import '../services/recording_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_visualizer.dart';

class FreeSpeakingScreen extends StatefulWidget {
  final DialogueScenario scenario;

  const FreeSpeakingScreen({
    super.key,
    this.scenario = const DialogueScenario(
      id: 'default',
      title: 'Conversação',
      partnerName: 'Emma',
      partnerBadge: 'Nativo US',
      avatarUrl: '',
      initialMessage: ChatMessage(
        id: 'init',
        sender: 'ai',
        text: 'Hello!',
        timestamp: 'Agora',
      ),
      rules: [],
      defaultRule: DialogueRule(id: 'def', keywords: [], reply: 'Okay!'),
    ),
  });

  @override
  State<FreeSpeakingScreen> createState() => _FreeSpeakingScreenState();
}

class _FreeSpeakingScreenState extends State<FreeSpeakingScreen> {
  final _tts = TtsService();
  final _recordingService = RecordingService();
  final _liveTranscript = LiveTranscriptService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  late DialogueScenario _scenario;
  final List<ChatMessage> _messages = [];

  bool _isRecording = false;
  bool _isProcessing = false;
  String _liveTranscriptText = '';
  String? _currentlySpeakingId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scenario = widget.scenario.id == 'default'
        ? coffeeNycScenario
        : widget.scenario;

    _messages.add(_scenario.initialMessage);

    // Automatically speak the initial AI greeting
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _playAiMessage(_scenario.initialMessage);
      }
    });
  }

  @override
  void dispose() {
    _tts.dispose();
    _recordingService.dispose();
    _liveTranscript.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _playAiMessage(ChatMessage msg) async {
    if (_currentlySpeakingId == msg.id) {
      await _tts.stop();
      setState(() => _currentlySpeakingId = null);
      return;
    }

    setState(() => _currentlySpeakingId = msg.id);
    await _tts.speak(msg.text);
    if (mounted) {
      setState(() => _currentlySpeakingId = null);
    }
  }

  String _formatTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _toggleRecording() async {
    if (_isProcessing) return;

    if (_isRecording) {
      // STOP recording
      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      final spokenFromStt = await _liveTranscript.stop();
      await _recordingService.stop();

      final userText = spokenFromStt.trim().isNotEmpty
          ? spokenFromStt.trim()
          : _liveTranscriptText.trim();

      setState(() {
        _isProcessing = false;
        _liveTranscriptText = '';
      });

      if (userText.isEmpty) {
        setState(() {
          _errorMessage =
              'Nenhuma fala detectada. Pressione o microfone ou digite sua resposta abaixo.';
        });
        return;
      }

      _handleUserMessage(userText);
    } else {
      // START recording
      setState(() {
        _errorMessage = null;
        _liveTranscriptText = '';
      });

      final permitted = await _recordingService.start();
      if (!permitted) {
        setState(() {
          _errorMessage =
              'Não foi possível acessar o microfone. Você pode digitar sua resposta no campo abaixo.';
        });
        return;
      }

      setState(() => _isRecording = true);

      await _liveTranscript.start(
        onResult: (text) {
          if (mounted) {
            setState(() => _liveTranscriptText = text);
          }
        },
      );
    }
  }

  void _handleUserMessage(String text) {
    setState(() {
      _errorMessage = null;
      _messages.add(
        ChatMessage(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          sender: 'user',
          text: text,
          timestamp: _formatTime(),
        ),
      );
    });
    _scrollToBottom();

    // Match AI response with a short delay for conversational rhythm
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      final matched = matchDialogueResponse(text, _scenario);
      final aiMsg = ChatMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        text: matched.text,
        timestamp: _formatTime(),
        suggestion: matched.suggestion,
      );

      setState(() {
        _messages.add(aiMsg);
      });
      _scrollToBottom();
      _playAiMessage(aiMsg);
    });
  }

  void _submitTypedMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _handleUserMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryContainer,
              child: Text(
                _scenario.partnerName[0],
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _scenario.partnerName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _scenario.partnerBadge,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _scenario.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
          // Error Banner if needed
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.dangerContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppTheme.danger),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          // Message Timeline
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isRecording ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isRecording) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WaveformVisualizer(
                            isRecording: _isRecording,
                            activeColor: AppTheme.primary,
                            barCount: 12,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _liveTranscriptText.isNotEmpty
                                ? _liveTranscriptText
                                : 'Ouvindo sua resposta...',
                            style: GoogleFonts.plusJakartaSans(
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final isAi = msg.isAi;
                final isSpeaking = _currentlySpeakingId == msg.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: isAi
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      // Bubble Container
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: min(
                            520.0,
                            MediaQuery.of(context).size.width * 0.82,
                          ),
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isAi ? Colors.white : AppTheme.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isAi ? 2 : 16),
                            bottomRight: Radius.circular(isAi ? 16 : 2),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                height: 1.45,
                                color: isAi
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isAi) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _playAiMessage(msg),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSpeaking
                                        ? AppTheme.primary
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSpeaking
                                            ? Icons.volume_up
                                            : Icons.play_arrow,
                                        size: 14,
                                        color: isSpeaking
                                            ? Colors.white
                                            : AppTheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isSpeaking
                                            ? 'Ouvindo...'
                                            : 'Ouvir resposta',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isSpeaking
                                              ? Colors.white
                                              : AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Timestamp
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                        child: Text(
                          msg.timestamp,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),

                      // Pedagogical Suggestion Pill
                      if (msg.suggestion != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: min(
                              520.0,
                              MediaQuery.of(context).size.width * 0.82,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  msg.suggestion!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: const Color(0xFF92400E),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Bar (Mic button + text input fallback)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: _isRecording
                            ? 'Gravando áudio...'
                            : 'Digite ou use o microfone...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide:
                              const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: AppTheme.primary),
                          onPressed: _submitTypedMessage,
                          tooltip: 'Enviar mensagem',
                        ),
                      ),
                      onSubmitted: (_) => _submitTypedMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Microphone Action Button
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            _isRecording ? AppTheme.danger : AppTheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? AppTheme.danger
                                    : AppTheme.primary)
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 24,
                      ),
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
