import 'package:flutter/material.dart';

import 'opencrono_element.dart';
import 'opencrono_element_widget.dart';

class OpenCronoSchedulerElement extends OpenCronoElement {
  const OpenCronoSchedulerElement({
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
        ? 'assets/images/elements/schedulers/calendar_on.png'
        : 'assets/images/elements/schedulers/calendar_off.png';
  }

  @override
  Widget buildElementWidget(BuildContext context) {
    final safeTitle = (title?.trim().isEmpty ?? true)
        ? 'Elemento ${id ?? ''}'
        : title!.trim();
    print(
      '[OPENCRONO WIDGET] build $runtimeType $safeTitle image=${getImageAsset()}',
    );
    return buildOpenCronoElementWidget(
      context: context,
      imageAsset: getImageAsset(),
      title: safeTitle,
      status: status,
    );
  }

  @override
  bool get isClickable => false;
}
