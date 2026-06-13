import 'opencrono_element.dart';

abstract class OpenCronoTimerElement extends OpenCronoElement {
  const OpenCronoTimerElement({
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
}
