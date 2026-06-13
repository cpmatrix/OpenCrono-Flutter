import 'opencrono_element.dart';

abstract class OpenCronoSchedulerElement extends OpenCronoElement {
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
}
