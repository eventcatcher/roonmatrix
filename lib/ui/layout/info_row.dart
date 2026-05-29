import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String text;
  final double fontSize;
  final AutoSizeGroup? group;
  final Color color;
  final int? maxLines;

  const InfoRow({
    super.key,
    required this.label,
    required this.text,
    required this.fontSize,
    this.group,
    required this.color,
    this.maxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //ConstrainedBox(
          //constraints: const BoxConstraints(minWidth: 70, maxWidth: 120),
          //child:
          AutoSizeText(
            label,
            group: group,
            maxLines: 1,
            minFontSize: 10,
            maxFontSize: 18,
            stepGranularity: 2,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: color.withValues(alpha: 0.7),
            ),
          ),

          //),
          const SizedBox(width: 6),

          Expanded(
            child: AutoSizeText(
              text,
              group: group,
              maxLines: 1,
              minFontSize: 10,
              maxFontSize: 18,
              stepGranularity: 2,
              wrapWords: true,
              overflowReplacement: Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
