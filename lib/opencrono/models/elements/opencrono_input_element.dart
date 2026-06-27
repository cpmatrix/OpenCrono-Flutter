import 'package:flutter/material.dart';

import 'opencrono_element.dart';
import 'opencrono_element_widget.dart';

class OpenCronoInputElement extends OpenCronoElement {
  const OpenCronoInputElement({
    super.id,
    super.type,
    super.status,
    super.currentValue,
    super.title,
    super.labelValue,
    super.idGroup,
    super.currentTextValue,
    super.userProperty,
  });

  @override
  String getImageAsset() {
    return status == 1
        ? 'assets/images/elements/inputs/input_on.png'
        : 'assets/images/elements/inputs/input_off.png';
  }

  @override
  Widget buildElementWidget(BuildContext context) {
    final safeTitle = (title?.trim().isEmpty ?? true)
        ? 'Elemento ${id ?? ''}'
        : title!.trim();
    final valueLabel = _buildValueLabel();
    print(
      '[OPENCRONO WIDGET] build $runtimeType $safeTitle image=${getImageAsset()}',
    );
    return buildOpenCronoElementWidget(
      context: context,
      imageAsset: getImageAsset(),
      title: safeTitle,
      status: status,
      titleInLeftArea: true,
      bottomCenterValue: valueLabel,
    );
  }

  String? _buildValueLabel() {
    final textValue = currentTextValue?.trim() ?? '';
    if (textValue.isNotEmpty && textValue != '0') {
      final symbol = labelValue?.trim() ?? '';
      return symbol.isEmpty ? textValue : '$textValue $symbol';
    }

    final numeric = currentValue ?? 0;
    if (numeric == 0) {
      return null;
    }

    final normalizedValue =
        numeric % 1 == 0 ? numeric.toInt().toString() : numeric.toString();
    final symbol = labelValue?.trim() ?? '';
    return symbol.isEmpty ? normalizedValue : '$normalizedValue $symbol';
  }

  @override
  bool get isClickable => false;
}
