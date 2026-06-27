import 'package:flutter/material.dart';

import '../../../core/utils/app_log.dart';
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
    AppLog.d(
      '[OPENCRONO VALUE] $safeTitle value=$currentValue label=$labelValue',
    );
    return buildOpenCronoElementWidget(
      context: context,
      imageAsset: getImageAsset(),
      title: safeTitle,
      status: status,
      titleInLeftArea: true,
      bottomCenterValue: valueLabel,
      bottomCenterBottom: 50,
    );
  }

  String? _buildValueLabel() {
    final symbol = labelValue?.trim() ?? '';
    final numeric = currentValue;
    if (numeric == null || numeric == 0) {
      return null;
    }

    final normalizedValue =
        numeric % 1 == 0 ? numeric.toInt().toString() : numeric.toString();

    if (symbol == 'mV') {
      return normalizedValue;
    }

    return symbol.isEmpty ? normalizedValue : '$normalizedValue $symbol';
  }

  @override
  bool get isClickable => false;
}
