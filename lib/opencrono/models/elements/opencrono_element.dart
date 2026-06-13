import 'package:flutter/widgets.dart';

abstract class OpenCronoElement {
  final String? id;
  final int? type;
  final int? status;
  final double? currentValue;
  final String? title;
  final String? labelValue;
  final int? idGroup;
  final String? currentTextValue;
  final String? userProperty;

  const OpenCronoElement({
    this.id,
    this.type,
    this.status,
    this.currentValue,
    this.title,
    this.labelValue,
    this.idGroup,
    this.currentTextValue,
    this.userProperty,
  });

  String getImageAsset();

  Widget buildElementWidget(BuildContext context);

  bool get isClickable;
}
