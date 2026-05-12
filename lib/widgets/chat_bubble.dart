import 'package:flutter/material.dart';
import '../config/app_theme.dart';

enum BubbleStyle { user, ai, system }

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.content, required this.style, super.key});
  final String content;
  final BubbleStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == BubbleStyle.system) return _systemBubble();
    final isUser = style == BubbleStyle.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.primaryGradient : null,
                color: isUser ? null : AppTheme.surfaceLight,
                borderRadius: isUser ? AppTheme.userBubbleRadius : AppTheme.aiBubbleRadius,
                border: isUser ? null : Border.all(color: Colors.white.withAlpha(77), width: 0.5),
                boxShadow: isUser ? const [AppTheme.cardShadow] : null,
              ),
              child: Text(
                content,
                style: TextStyle(fontSize: 15, color: isUser ? Colors.white : AppTheme.textPrimary, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemBubble() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7).withAlpha(200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(content, style: AppTheme.tinyText.copyWith(color: const Color(0xFF92400E))),
      ),
    ),
  );
}

