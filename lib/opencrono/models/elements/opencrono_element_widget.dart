import 'package:flutter/material.dart';

Widget buildOpenCronoElementWidget({
  required BuildContext context,
  required String imageAsset,
  required String title,
  required int? status,
  bool titleAboveImage = false,
  bool titleInLeftArea = false,
  String? bottomCenterValue,
  double bottomCenterBottom = 10,
}) {
  final normalizedBottomValue = (bottomCenterValue ?? '').trim();
  final shouldShowBottomValue = normalizedBottomValue.isNotEmpty &&
      !_isZeroValueLabel(normalizedBottomValue);
    final loweredBottomOffset = bottomCenterBottom - 5;
    final effectiveBottomCenterBottom =
      loweredBottomOffset < 15 ? 15.0 : loweredBottomOffset;

  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(
                imageAsset,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  print('[OPENCRONO IMAGE ERROR] $imageAsset');
                  return const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 34,
                  );
                },
              ),
            ),
            if (titleAboveImage)
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            if (titleInLeftArea)
              Positioned(
                left: constraints.maxWidth * 0.08,
                right: constraints.maxWidth * 0.42,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (!titleAboveImage)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.10,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (shouldShowBottomValue)
              Positioned(
                left: 10,
                right: 10,
                bottom: effectiveBottomCenterBottom,
                child: Text(
                  normalizedBottomValue,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

bool _isZeroValueLabel(String valueLabel) {
  final parts = valueLabel.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) {
    return true;
  }

  final numericPart = parts.first.replaceAll(',', '.');
  final parsedNumeric = double.tryParse(numericPart);
  if (parsedNumeric == null) {
    return false;
  }

  return parsedNumeric == 0;
}
