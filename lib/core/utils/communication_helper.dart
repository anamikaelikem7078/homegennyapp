import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../design_system/design_system.dart';

/// Resilient communication helper for calling phone numbers.
abstract final class CommunicationHelper {
  /// Initiates a phone call to the target [phoneNumber].
  ///
  /// On emulators or devices without telephony support, it displays a
  /// high-fidelity simulated call interface so the user is wowed.
  static Future<void> makePhoneCall(BuildContext context, String phoneNumber, {String? recipientName}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final callUri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        // Fall back to a beautiful simulated call screen
        if (context.mounted) {
          _showSimulatedCall(context, phoneNumber, recipientName ?? 'HomeGenny Support');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSimulatedCall(context, phoneNumber, recipientName ?? 'HomeGenny Support');
      }
    }
  }

  static void _showSimulatedCall(BuildContext context, String rawNumber, String displayName) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A), // Premium dark mode slate background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return _SimulatedCallWidget(
          displayName: displayName,
          phoneNumber: rawNumber,
        );
      },
    );
  }
}

class _SimulatedCallWidget extends StatefulWidget {
  const _SimulatedCallWidget({
    required this.displayName,
    required this.phoneNumber,
  });

  final String displayName;
  final String phoneNumber;

  @override
  State<_SimulatedCallWidget> createState() => _SimulatedCallWidgetState();
}

class _SimulatedCallWidgetState extends State<_SimulatedCallWidget> {
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top indicator bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),

          // Calling Status Header
          Column(
            children: [
              Text(
                'SIMULATED CALL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A56FF), // Neon blue brand highlight
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.displayName,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.phoneNumber,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 24),
              
              // Timer indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_seconds),
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Center pulsing graphic / avatar placeholder
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring 2
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A56FF).withOpacity(0.04),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 2.seconds, curve: Curves.easeOut)
                      .fadeOut(duration: 2.seconds),
                      
                  // Outer pulse ring 1
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A56FF).withOpacity(0.08),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), delay: 500.ms, duration: 2.seconds, curve: Curves.easeOut)
                      .fadeOut(duration: 2.seconds),

                  // Call avatar circle
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1F2937),
                      border: Border.all(color: const Color(0xFF1A56FF), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.displayName.isNotEmpty ? widget.displayName[0].toUpperCase() : 'H',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A56FF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Copy number trigger
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.phoneNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number copied to clipboard!'),
                  backgroundColor: Color(0xFF1A56FF),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.copy, size: 16, color: Colors.white54),
                const SizedBox(width: 8),
                Text(
                  'Copy Number',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Mid actions (Mute, Keypad, Speaker)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallActionButton(
                icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                label: 'Mute',
                isActive: _isMuted,
                onPressed: () {
                  setState(() {
                    _isMuted = !_isMuted;
                  });
                },
              ),
              _CallActionButton(
                icon: Icons.dialpad_rounded,
                label: 'Keypad',
                onPressed: () {},
              ),
              _CallActionButton(
                icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                label: 'Speaker',
                isActive: _isSpeaker,
                onPressed: () {
                  setState(() {
                    _isSpeaker = !_isSpeaker;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 48),

          // Bottom Action: Red End Call button
          FloatingActionButton.large(
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.call_end_rounded, size: 36),
          ),
          
          const SizedBox(height: 10),
          Text(
            'END CONNECTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.08),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0F172A) : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
