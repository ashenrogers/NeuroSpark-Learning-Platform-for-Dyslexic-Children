import 'package:flutter/material.dart';

class FeedbackDialog extends StatelessWidget {
  final bool isCorrect;
  final String message;
  final String? details;
  final VoidCallback? onContinue;

  const FeedbackDialog({
    super.key,
    required this.isCorrect,
    required this.message,
    this.details,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect ? 'Great Job! 🎉' : 'Keep Trying! 💪',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: 12),
              Text(
                details!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onContinue != null) {
                  onContinue!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? Colors.green : Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required bool isCorrect,
    required String message,
    String? details,
    VoidCallback? onContinue,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FeedbackDialog(
        isCorrect: isCorrect,
        message: message,
        details: details,
        onContinue: onContinue,
      ),
    );
  }
}
