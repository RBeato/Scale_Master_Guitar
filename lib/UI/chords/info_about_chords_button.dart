import 'package:flutter/material.dart';

class InfoAboutChordsIcon extends StatefulWidget {
  const InfoAboutChordsIcon({super.key});

  @override
  State<InfoAboutChordsIcon> createState() => _InfoAboutChordsIconState();
}

class _InfoAboutChordsIconState extends State<InfoAboutChordsIcon> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF262C36),
              title: const Text('Chord Selection',
                  style: TextStyle(color: Colors.white54)),
              content: const Text(
                'Tap once to select a chord with the duration of 2 beats, tap twice to select a chord with the duration of 4 beats.',
                textAlign: TextAlign.justify,
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          Icons.info_outline,
          color: Colors.orange,
        ),
      ),
    );
  }
}
