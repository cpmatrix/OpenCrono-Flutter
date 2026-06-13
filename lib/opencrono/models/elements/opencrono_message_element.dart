import 'package:flutter/widgets.dart';

import 'opencrono_element.dart';

class OpenCronoMessageElement extends OpenCronoElement {
  const OpenCronoMessageElement({
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
    // TODO: return real asset path when element rendering is implemented.
    return '';
  }

  @override
  Widget buildElementWidget(BuildContext context) {
    // TODO: replace placeholder widget with actual OpenCrono message UI.
    return const SizedBox.shrink();
  }

  @override
  bool get isClickable => false;
}
