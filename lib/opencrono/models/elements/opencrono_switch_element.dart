import 'opencrono_element.dart';

abstract class OpenCronoSwitchElement extends OpenCronoElement {
  const OpenCronoSwitchElement({
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
