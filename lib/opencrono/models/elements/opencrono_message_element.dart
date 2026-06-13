import 'opencrono_element.dart';

abstract class OpenCronoMessageElement extends OpenCronoElement {
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
}
