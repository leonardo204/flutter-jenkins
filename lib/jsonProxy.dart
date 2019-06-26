import 'dart:async';

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jenkins/tab/settingScreen.dart';

class JsonProxy {
  Future<List> getStbList(String site) async {
    List<String> stbList = new List<String>();

    SettingScreen setting = new SettingScreen();

    String username = SettingScreen.user_id;
    String password = SettingScreen.user_password;
    String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));

    var addr1 = SettingScreen.user_addr + "/job/";
    var addr2 = "/api/json?depth=1";
    var url = addr1 + site + addr2;
    print('url(${url}) -  id(${username})');

    if (url==null || url.indexOf("http://") != 0) {
      stbList.add('-1');
      return stbList;
    }

    var response;

    try {
      response = await http.get(
        url,
        headers: {HttpHeaders.authorizationHeader: basicAuth},
      ).then((response) {

        print('- result -');
        print('resCode=${response.statusCode}');
        //print('${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          List<dynamic> info = parseJson(response.body);

          //print('parsed=${info.toString()}');
          for (var n in info) {
            stbList.add(n);
          }
        } else {
          stbList = null;
        }

      }).timeout(const Duration(seconds: 10));

    } on TimeoutException catch (e) {
      print('request timeout: ${e.toString()}');
      stbList = null;
    } on SocketException catch (e) {
      print('socket exception: ${e.toString()}');
      stbList = null;
    } catch (e) {
      stbList = null;
      print('error: ${e.toString()}');
    }

    return stbList;
  }

  List<dynamic> parseJson(String response) {
    Map<String, dynamic> parsed1 = json.decode(response);
    var p1 = TotalInfo.fromJson(parsed1);
    //print('p1.actions=${p1.actions}');
    String p1action = jsonEncode(p1.actions);
    int idx = p1action.indexOf('{}');
    String p1final = p1action.substring(1, idx - 1);

    //print('p1final=${p1final}');

    Map<String, dynamic> parsed2 = json.decode(p1final);
    //print('parsed2=${parsed2.toString()}');
    var p2 = ActionInfo.fromJson(parsed2);
    String p2param = jsonEncode(p2.parameterDefinitions);
    idx = p2param.indexOf(']},');
    String p2final = p2param.substring(1, idx + 2);

    //print('p2final=${p2final}');

    Map<String, dynamic> parsed3 = json.decode(p2final);
    var p3 = ParamInfo.fromJson(parsed3);
    print('p3.choices=${p3.choices}');

    return p3.choices;
  }
}

class ParamInfo {
  final String clazz;
  final dynamic defaultParameterValue;
  final String description;
  final String name;
  final String type;
  final dynamic choices;

  ParamInfo(
      {this.clazz,
      this.defaultParameterValue,
      this.description,
      this.name,
      this.type,
      this.choices});

  ParamInfo.fromJson(Map<String, dynamic> json)
      : clazz = json['_class'],
        defaultParameterValue = json['defaultParameterValue'],
        description = json['description'],
        name = json['name'],
        type = json['type'],
        choices = json['choices'];
}

class ActionInfo {
  final String clazz;
  final dynamic parameterDefinitions;

  ActionInfo({
    this.clazz,
    this.parameterDefinitions,
  });

  ActionInfo.fromJson(Map<String, dynamic> json)
      : clazz = json['_class'],
        parameterDefinitions = json['parameterDefinitions'];

  Map<String, dynamic> toJson() =>
      {'_class': clazz, 'parameterDefinitions': parameterDefinitions};
}

class TotalInfo {
  final String clazz;
  final dynamic actions;
  final String description;
  final String displayName;
  final String displayNameOrNull;
  final String fullDisplayName;
  final String fullName;
  final String name;
  final String url;
  final String allBuilds;
  final bool buildable;
  final dynamic builds;
  final String color;
  final dynamic firstBuild;
  final dynamic healthReport;
  final bool inQueue;
  final bool keepDependencies;
  final dynamic lastBuild;
  final dynamic lastCompletedBuild;
  final dynamic lastFailedBuild;
  final dynamic lastStableBuild;
  final dynamic lastSuccessfulBuild;
  final dynamic lastUnstableBuild;
  final dynamic lastUnsuccessfulBuild;
  final int nextBuildNumber;
  final dynamic property;
  final String queueItem;
  final bool concurrentBuild;
  final dynamic downstreamProjects;
  final String labelExpression;
  final dynamic scm;
  final dynamic upstreamProjects;

  TotalInfo({
    this.clazz,
    this.actions,
    this.description,
    this.displayName,
    this.displayNameOrNull,
    this.fullDisplayName,
    this.fullName,
    this.name,
    this.url,
    this.allBuilds,
    this.buildable,
    this.builds,
    this.color,
    this.firstBuild,
    this.healthReport,
    this.inQueue,
    this.keepDependencies,
    this.lastBuild,
    this.lastCompletedBuild,
    this.lastFailedBuild,
    this.lastStableBuild,
    this.lastSuccessfulBuild,
    this.lastUnstableBuild,
    this.lastUnsuccessfulBuild,
    this.nextBuildNumber,
    this.property,
    this.queueItem,
    this.concurrentBuild,
    this.downstreamProjects,
    this.labelExpression,
    this.scm,
    this.upstreamProjects,
  });

  TotalInfo.fromJson(Map<String, dynamic> json)
      : clazz = json['_class'],
        actions = json['actions'],
        description = json['description'],
        displayName = json['displayName'],
        displayNameOrNull = json['displayNameOrNull'],
        fullDisplayName = json['fullDisplayName'],
        fullName = json['fullName'],
        name = json['name'],
        url = json['url'],
        allBuilds = json['allBuilds'],
        buildable = json['buildable'],
        builds = json['builds'],
        color = json['color'],
        firstBuild = json['firstBuild'],
        healthReport = json['healthReport'],
        inQueue = json['inQueue'],
        keepDependencies = json['keepDependencies'],
        lastBuild = json['lastBuild'],
        lastCompletedBuild = json['lastCompletedBuild'],
        lastFailedBuild = json['lastFailedBuild'],
        lastStableBuild = json['lastStableBuild'],
        lastSuccessfulBuild = json['lastSuccessfulBuild'],
        lastUnstableBuild = json['lastUnstableBuild'],
        lastUnsuccessfulBuild = json['lastUnsuccessfulBuild'],
        nextBuildNumber = json['nextBuildNumber'],
        property = json['property'],
        queueItem = json['queueItem'],
        concurrentBuild = json['concurrentBuild'],
        downstreamProjects = json['downstreamProjects'],
        labelExpression = json['labelExpression'],
        scm = json['scm'],
        upstreamProjects = json['upstreamProjects'];
}
