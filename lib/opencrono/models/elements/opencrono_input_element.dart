import 'opencrono_element.dart';

abstract class OpenCronoInputElement extends OpenCronoElement {
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
}
