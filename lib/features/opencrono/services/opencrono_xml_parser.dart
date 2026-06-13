import 'dart:convert';

import 'package:xml/xml.dart';

import '../models/opencrono_element.dart';

class OpenCronoXmlParser {
  List<OpenCronoElementData> parseElementsStatus(String xml) {
    try {
      final document = XmlDocument.parse(xml);
      final elements = document.findAllElements('elemento');

      return elements.map(_mapXmlElement).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  OpenCronoElementData _mapXmlElement(XmlElement element) {
    final attributes = <String, String>{
      for (final attribute in element.attributes)
        attribute.name.local: attribute.value,
    };

    final userPropertyRaw = _readString(attributes, 'user_property');

    return OpenCronoElementData(
      id: _readInt(attributes, 'id'),
      type: _readInt(attributes, 'type'),
      status: _readInt(attributes, 'status'),
      currentValue: _readDouble(attributes, 'currentvalue'),
      title: _readString(attributes, 'title'),
      labelValue: _readString(attributes, 'label_value'),
      idGroup: _readInt(attributes, 'id_group'),
      currentTextValue: _readString(attributes, 'currenttextvalue'),
      userPropertyRaw: userPropertyRaw,
      userProperty: _decodeUserProperty(userPropertyRaw),
      updateNumericValue: _readBool(attributes, 'update_numeric_value'),
      numericValueFromUserRange:
          _readString(attributes, 'numeric_value_from_user_range'),
      updateStringValue: _readBool(attributes, 'update_string_value'),
      desGroup: _readString(attributes, 'des_group'),
      rawAttributes: attributes,
    );
  }

  Map<String, dynamic>? _decodeUserProperty(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }

    try {
      final decodedBytes = base64Decode(raw.trim());
      final decodedText = utf8.decode(decodedBytes);
      final decodedJson = jsonDecode(decodedText);
      if (decodedJson is Map<String, dynamic>) {
        return decodedJson;
      }
      if (decodedJson is Map) {
        return decodedJson.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  int _readInt(Map<String, String> attributes, String key) {
    final value = attributes[key];
    if (value == null) {
      return 0;
    }
    return int.tryParse(value.trim()) ?? 0;
  }

  double _readDouble(Map<String, String> attributes, String key) {
    final value = attributes[key];
    if (value == null) {
      return 0;
    }
    return double.tryParse(value.trim()) ?? 0;
  }

  bool _readBool(Map<String, String> attributes, String key) {
    final value = attributes[key];
    if (value == null) {
      return false;
    }

    final normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  String _readString(Map<String, String> attributes, String key) {
    return attributes[key]?.trim() ?? '';
  }
}
