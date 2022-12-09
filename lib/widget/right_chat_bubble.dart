import 'package:flutter/material.dart';

import 'custom_painter.dart';

class RightChatBubble extends StatelessWidget {
  final String? message;

  const RightChatBubble({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.only(
                    top: 14, bottom: 14.0, right: 25.0, left: 14.0),
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(
                  message.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(4.0),
              //   child: Icon(
              //     Icons.done_all,
              //     size: 18,
              //     color: seen == true ? Colors.black : Colors.white,
              //   ),
              // )
            ],
          ),
        ),
        CustomPaint(painter: CustomShape(Colors.blue.shade700)),
      ],
    );
  }
}
