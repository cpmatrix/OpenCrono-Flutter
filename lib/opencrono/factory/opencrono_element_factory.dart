import 'package:flutter/widgets.dart';

import '../models/elements/opencrono_element.dart';
import '../models/elements/opencrono_element_widget.dart';
import '../models/elements/opencrono_group_element.dart';
import '../models/elements/opencrono_input_element.dart';
import '../models/elements/opencrono_message_element.dart';
import '../models/elements/opencrono_monitor_element.dart';
import '../models/elements/opencrono_scheduler_element.dart';
import '../models/elements/opencrono_switch_element.dart';
import '../models/elements/opencrono_timer_element.dart';

class OpenCronoElementFactory {
  const OpenCronoElementFactory._();

  static OpenCronoElement create({
    required int type,
    String? id,
    int? status,
    double? currentValue,
    String? title,
    String? labelValue,
    int? idGroup,
    String? currentTextValue,
    String? userProperty,
  }) {
    final element = switch (type) {
      2 => OpenCronoSchedulerElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
      5 => OpenCronoInputElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
      6 => OpenCronoTimerElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
      7 => OpenCronoAnalogInputElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
      9 => OpenCronoMonitorElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
      10 => OpenCronoMessageElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
      11 => OpenCronoGroupElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
      _ => OpenCronoSwitchElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        ),
    };

    print('[FACTORY] type=$type -> ${element.runtimeType} -> ${title ?? ''}');
    return element;
  }
}

class OpenCronoAnalogInputElement extends OpenCronoSwitchElement {
  const OpenCronoAnalogInputElement({
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
}
