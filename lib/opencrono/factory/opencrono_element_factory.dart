import '../models/elements/opencrono_element.dart';
import '../models/elements/opencrono_group_element.dart';

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
    switch (type) {
      case 11:
        return OpenCronoGroupElement(
          id: id,
          type: type,
          status: status,
          currentValue: currentValue,
          title: title,
          labelValue: labelValue,
          idGroup: idGroup,
          currentTextValue: currentTextValue,
          userProperty: userProperty,
        );
      default:
        throw UnsupportedError('Unsupported OpenCrono TYPE: $type');
    }
  }
}
