import 'package:flutter/material.dart';

class CustomPianoKey extends StatefulWidget {
  final bool isBlack;
  final String note;
  final Function(String) onKeyDown;
  final Function(String) onKeyUp;
  final bool isInScale;
  final Color? containerColor;

  const CustomPianoKey({
    super.key,
    required this.isBlack,
    required this.note,
    required this.onKeyDown,
    required this.onKeyUp,
    required this.containerColor,
    this.isInScale = false,
  });

  @override
  State<CustomPianoKey> createState() => _CustomPianoKeyState();
}

class _CustomPianoKeyState extends State<CustomPianoKey> {
  bool _isPressed = false;

  void _onKeyTapDown(TapDownDetails details) {
    if (!_isPressed) {
      setState(() {
        _isPressed = true;
      });
      final String keyContext = 'CustomPianoKey[\${widget.note}]';
      debugPrint('[$keyContext] KEY DOWN. Calling onKeyDown("${widget.note}")');
      widget.onKeyDown(widget.note);
    }
  }

  void _onKeyTapUp(TapUpDetails details) {
    if (_isPressed) { // Check if it was pressed to avoid redundant calls if drag-off already handled it
      setState(() {
        _isPressed = false;
      });
      final String keyContext = 'CustomPianoKey[\${widget.note}]';
      debugPrint('[$keyContext] KEY UP. Calling onKeyUp("${widget.note}")');
      widget.onKeyUp(widget.note);
    }
  }

  void _onKeyTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      final String keyContext = 'CustomPianoKey[\${widget.note}]';
      debugPrint('[$keyContext] KEY CANCEL (e.g., drag off). Calling onKeyUp("${widget.note}")');
      widget.onKeyUp(widget.note); // Treat cancel as key up
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isBlack ? Colors.black : Colors.white;
    final pressedColor = widget.isBlack ? Colors.black87 : Colors.white70;
    const textColor = Colors.grey;

    return GestureDetector(
      onTapDown: _onKeyTapDown,
      onTapUp: _onKeyTapUp,
      onTapCancel: _onKeyTapCancel,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _isPressed ? pressedColor : color,
              boxShadow: _isPressed
                  ? null
                  : [
                      const BoxShadow(
                        color: Colors.black45,
                        offset: Offset(0.0, 2.0),
                        blurRadius: 2.0,
                      ),
                    ],
              border: widget.isBlack
                  ? null
                  : Border(
                      right:
                          BorderSide(width: 1.0, color: Colors.grey.shade800),
                    ),
            ),
            height: widget.isBlack ? 100 : 150,
            width: widget.isBlack ? 25 : 40,
            alignment: Alignment.bottomCenter,
            child: Text(
              widget.note,
              textAlign: TextAlign.center,
              style: const TextStyle(color: textColor, fontSize: 12),
            ),
          ),
          if (widget.isInScale) // Add oval container if the key is in the scale
            Positioned(
              bottom: 1,
              left: 4,
              right: 4,
              // left: 10,
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.containerColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
