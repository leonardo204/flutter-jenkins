import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:convert';

class JsonManager {
  String myJson;
  var target;

  Future<bool> loadJsonFile(String path, bool isDefault) async {
    print('loading($path) rootBundle(${isDefault})');
    if (isDefault) {
      myJson = await rootBundle.loadString(path);
    } else {
      final file = await new File('$path');
      myJson = await file.readAsStringSync();
    }
    if (myJson == null) return false;
    return true;
  }

  String toString() {
    if (myJson == null) {
      return null;
    }
    return json.decode(myJson).toString();
  }

  void setJson(var jjson) {
    myJson = jjson;
  }

  void setTarget(var ttarget) {
    target = ttarget;
  }

  String getValue(String name) {
    for (var word in target) {
      if (word['name'] == name) return word['value'].toString();
    }
    return null;
  }

  bool setValue(String name, String value) {
    for (var word in target) {
      if (word['name'] == name) {
        word['value'] = value;
        return true;
      }
    }
    return false;
  }
}
