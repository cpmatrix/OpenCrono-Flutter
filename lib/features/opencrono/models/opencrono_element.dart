class OpenCronoElement {
  const OpenCronoElement({
    required this.id,
    required this.type,
    required this.status,
    required this.currentValue,
    required this.title,
    required this.labelValue,
    required this.idGroup,
    required this.currentTextValue,
    required this.userPropertyRaw,
    required this.userProperty,
    required this.updateNumericValue,
    required this.numericValueFromUserRange,
    required this.updateStringValue,
    required this.desGroup,
    required this.rawAttributes,
  });

  final int id;
  final int type;
  final int status;
  final double currentValue;
  final String title;
  final String labelValue;
  final int idGroup;
  final String currentTextValue;
  final String userPropertyRaw;
  final Map<String, dynamic>? userProperty;
  final bool updateNumericValue;
  final String numericValueFromUserRange;
  final bool updateStringValue;
  final String desGroup;
  final Map<String, String> rawAttributes;
}
