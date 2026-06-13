import 'opencrono_element.dart';

abstract class OpenCronoGroupElement extends OpenCronoElement {
  const OpenCronoGroupElement({
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
