import 'package:flutter/material.dart';

Widget buildOpenCronoElementWidget({
  required BuildContext context,
  required String imageAsset,
  required String title,
  required int? status,
  bool showStatus = true,
  bool titleAboveImage = false,
  bool titleInLeftArea = false,
}) {
  final isActive = status == 1;

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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                ),
              ),
            if (showStatus)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF7CF3A0)
                        : const Color(0xFF4A5563),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
