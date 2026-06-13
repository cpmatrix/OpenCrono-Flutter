import 'opencrono_element.dart';

abstract class OpenCronoMonitorElement extends OpenCronoElement {
  const OpenCronoMonitorElement({
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
