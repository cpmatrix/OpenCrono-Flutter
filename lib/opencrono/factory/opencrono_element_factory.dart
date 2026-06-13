import '../models/elements/opencrono_element.dart';

class OpenCronoElementFactory {
  const OpenCronoElementFactory._();

  static OpenCronoElement create({
    required String type,
    String? id,
    String? status,
    String? currentValue,
    String? title,
    String? labelValue,
    String? idGroup,
    String? currentTextValue,
    String? userProperty,
  }) {
    // TODO: implement TYPE mapping and instantiate specialized OpenCronoElement subclasses.
    throw UnimplementedError(
      'OpenCronoElementFactory.create is not implemented yet for type: $type',
    );
  }
}
