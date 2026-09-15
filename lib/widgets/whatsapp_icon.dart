import 'package:flutter/material.dart';

class WhatsAppIcon extends StatelessWidget {
  final double size;

  const WhatsAppIcon({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF25D366),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.chat_bubble,
            color: Colors.white,
            size: size * 0.72,
          ),
          Icon(
            Icons.call,
            color: const Color(0xFF25D366),
            size: size * 0.38,
          ),
        ],
      ),
    );
  }
}
