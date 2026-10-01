import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated audio waveform visualizer that renders pulsing frequency bars
/// while microphone recording is active, giving rich feedback to the user.
class WaveformVisualizer extends StatefulWidget {
  final bool isRecording;
  final Color activeColor;
  final int barCount;
  final double height;

  const WaveformVisualizer({
    super.key,
    required this.isRecording,
    this.activeColor = AppTheme.danger,
    this.barCount = 18,
    this.height = 36.0,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.isRecording) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isRecording && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              // Generate organic wave heights with staggered phase offsets
              final phase = (index / widget.barCount) * 2 * pi;
              final t = _controller.value * 2 * pi;
              final wave = (sin(t + phase) + 1.0) / 2.0;

              // Center bars are typically higher in voice representation
              final centerWeight =
                  1.0 - (index - widget.barCount / 2).abs() / (widget.barCount / 1.5);
              final normalizedHeight =
                  (0.20 + 0.80 * wave * max(0.35, centerWeight)) * widget.height;

              return Container(
                width: 3.5,
                height: max(4.0, normalizedHeight),
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color: widget.activeColor.withValues(
                    alpha: 0.45 + 0.55 * wave,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
