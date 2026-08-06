import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../design_system/design_system.dart';
import '../../../../core/utils/communication_helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.recipientName,
    this.recipientRole,
    this.avatarUrl,
  });

  final String? recipientName;
  final String? recipientRole;
  final String? avatarUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  _ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.attachmentPath,
    this.isAttachment = false,
  });

  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? attachmentPath;
  final bool isAttachment;
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  late final String _targetName;
  late final String _targetRole;
  late final String _avatar;

  @override
  void initState() {
    super.initState();
    _targetName = widget.recipientName ?? 'HomeGenny Concierge';
    _targetRole = widget.recipientRole ?? 'Support Specialist';
    _avatar = widget.avatarUrl ?? 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200';

    // Populate initial welcome messages to make the chat feel alive
    _messages.addAll([
      _ChatMessage(
        text: 'Hello! Welcome to HomeGenny Concierge Services.',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      _ChatMessage(
        text: 'How can I assist you with your stay or shift today?',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isMe: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Trigger mock concierge reply with delay
    _simulateResponse(text);
  }

  void _simulateResponse(String userQuery) {
    Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      // Determine response based on user keywords
      final query = userQuery.toLowerCase();
      String replyText = '';

      if (query.contains('salary') || query.contains('pay') || query.contains('money')) {
        replyText = 'Our finance department processes payments on the 1st of every month. Your current payslip details and transaction history can be viewed in the Payments section of your dashboard.';
      } else if (query.contains('check-in') || query.contains('shift') || query.contains('check out')) {
        replyText = 'I see you have an inquiry regarding your shift attendance. Let me check your check-in status with the coordinator on duty. Please stay near the designated property.';
      } else if (query.contains('document') || query.contains('tax') || query.contains('upload')) {
        replyText = 'To submit tax declarations or missing documents, please visit the Salary/Documents section in settings. If you encounter upload errors, make sure files are under 5MB.';
      } else if (query.contains('smart lock') || query.contains('code') || query.contains('lock')) {
        replyText = 'Smart lock codes are generated 24 hours prior to check-in. If your current code is not working, try holding the lock button for 3 seconds to reset the connection.';
      } else if (query.contains('help') || query.contains('assistance')) {
        replyText = 'I can help you resolve check-in/out issues, find shift updates, review salary slips, or contact property staff. Let me know what you need!';
      } else {
        replyText = 'Thank you for your message! Our team has received your inquiry regarding "$userQuery" and a specialist is reviewing it now. We typically respond in under 2 minutes.';
      }

      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: replyText,
          isMe: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _simulateAttachment() {
    setState(() {
      _messages.add(_ChatMessage(
        text: 'Sent an attachment: property_photo.jpg',
        isMe: true,
        timestamp: DateTime.now(),
        isAttachment: true,
        attachmentPath: 'assets/images/photo_placeholder.png',
      ));
      _isTyping = true;
    });
    _scrollToBottom();
    
    // Simulate a reply recognizing the attachment
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: 'Thank you for sending the photo. I have logged this to your shift log file. A coordinator will review it shortly.',
          isMe: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final slateBg = const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: slateBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(_avatar),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _targetName,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  _targetRole,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone_outlined, color: primaryColor),
            onPressed: () {
              // Initiate simulated call directly from active chat
              CommunicationHelper.makePhoneCall(context, '+18005550199', recipientName: _targetName);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, primaryColor)
                      .animate()
                      .fade(duration: 200.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                },
              ),
            ),

            // Pre-chat suggestions chips
            if (_messages.length <= 4) ...[
              _buildSuggestions(primaryColor),
              const SizedBox(height: 8),
            ],

            // Typing Indicator
            if (_isTyping) _buildTypingIndicator(slateBg),

            // Input panel
            _buildInputPanel(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(Color brandBlue) {
    final suggestions = [
      'Help with check-in',
      'When is payment processed?',
      'Coordinator support',
      'Smart lock issue'
    ];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final label = suggestions[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              onPressed: () => _sendMessage(label),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, Color brandBlue) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(_avatar),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? brandBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.isAttachment) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, color: isMe ? Colors.white70 : brandBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Attachment',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_outline_rounded, size: 12, color: brandBlue),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Color bg) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(_avatar),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.6, delay: (i * 150).ms, duration: 400.ms);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel(Color brandBlue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Attachment simulation
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF64748B)),
            onPressed: _simulateAttachment,
          ),
          
          // Text Input Box
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Send Button
          GestureDetector(
            onTap: () => _sendMessage(_messageController.text),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: brandBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
