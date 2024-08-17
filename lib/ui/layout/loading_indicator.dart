import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (message != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(message!)),
            const CircularProgressIndicator(),
          ],
        ),
      );
}
