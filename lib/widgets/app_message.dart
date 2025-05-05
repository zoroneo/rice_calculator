import 'package:flutter/material.dart';

class AppMessage extends StatelessWidget {
  final String message;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRetry;

  const AppMessage({
    super.key,
    required this.message,
    this.isLoading = false,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
            ],
            if (isError)
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
            if (!isLoading && !isError)
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color:
                    isError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
