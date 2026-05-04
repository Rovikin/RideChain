import 'package:flutter/material.dart';

class ArbiterRatingWidget extends StatefulWidget {
  final void Function(int rating) onRated;
  const ArbiterRatingWidget({super.key, required this.onRated});

  @override
  State<ArbiterRatingWidget> createState() => _ArbiterRatingWidgetState();
}

class _ArbiterRatingWidgetState extends State<ArbiterRatingWidget> {
  int _selected = 0;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return const Text(
        'Rating berhasil dikirim. Terima kasih.',
        style: TextStyle(color: Colors.green),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            return IconButton(
              onPressed: () => setState(() => _selected = star),
              icon: Icon(
                star <= _selected ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size:  36,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selected > 0
              ? () {
                  setState(() => _submitted = true);
                  widget.onRated(_selected);
                }
              : null,
          child: const Text('Kirim Rating'),
        ),
      ],
    );
  }
}
