import 'dart:io';

import 'package:dio/dio.dart';

import '../../utils.dart';

class ToolUpdateService {
  factory ToolUpdateService() {
    return _instance;
  }
  const ToolUpdateService._private();
  static final Map<String, dynamic> _data = {};
  Map<String, dynamic> get data => _data;

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
  static final _options = Options(
    headers: {
      'user-agent':
          'Mozilla/5.0 (Windows NT 10.0; rv:107.0) Gecko/20100101 Firefox/107.0',
      'content-type': 'application/json;charset=utf-8',
      'accept': 'application/json',
    },
  );

  static const _githubAPI =
      'https://api.github.com/repos/meetrevision/revision-tool/releases/latest';

  static final Directory _tempDir = Directory.systemTemp;

  static const _instance = ToolUpdateService._private();

  Future<void> fetchData() async {
    if (_data.isNotEmpty) {
      _data.clear();
    }

    final Response<dynamic> response = await _dio.get(
      _githubAPI,
      options: _options,
    );

    final responseJson = Map<String, dynamic>.from(
      response.data as Map<String, dynamic>,
    );
    _data.addAll(responseJson);
  }

  static int compareVersions(String left, String right) {
    final _ParsedVersion leftVersion = _ParsedVersion.parse(left);
    final _ParsedVersion rightVersion = _ParsedVersion.parse(right);

    final int coreMax = leftVersion.core.length > rightVersion.core.length
        ? leftVersion.core.length
        : rightVersion.core.length;
    for (int i = 0; i < coreMax; i++) {
      final int l = i < leftVersion.core.length ? leftVersion.core[i] : 0;
      final int r = i < rightVersion.core.length ? rightVersion.core[i] : 0;
      if (l != r) return l.compareTo(r);
    }

    if (leftVersion.preRelease.isEmpty && rightVersion.preRelease.isEmpty) {
      return 0;
    }
    if (leftVersion.preRelease.isEmpty) return 1;
    if (rightVersion.preRelease.isEmpty) return -1;

    final int preMax =
        leftVersion.preRelease.length > rightVersion.preRelease.length
        ? leftVersion.preRelease.length
        : rightVersion.preRelease.length;
    for (int i = 0; i < preMax; i++) {
      if (i >= leftVersion.preRelease.length) return -1;
      if (i >= rightVersion.preRelease.length) return 1;

      final String l = leftVersion.preRelease[i];
      final String r = rightVersion.preRelease[i];
      final int? lNumber = int.tryParse(l);
      final int? rNumber = int.tryParse(r);

      if (lNumber != null && rNumber != null) {
        if (lNumber != rNumber) return lNumber.compareTo(rNumber);
        continue;
      }
      if (lNumber != null) return -1;
      if (rNumber != null) return 1;

      final int stringCmp = l.compareTo(r);
      if (stringCmp != 0) return stringCmp;
    }

    return 0;
  }

  bool get isLatestVersionNewer {
    final String? latest = _latestTagName;
    if (latest == null) return false;
    return compareVersions(latest, _currentAppVersion) > 0;
  }

  int get getCurrentVersion {
    return _toSortableInt(_currentAppVersion);
  }

  int get getLatestVersion {
    final String? latest = _latestTagName;
    if (latest == null) return -1;
    return _toSortableInt(latest);
  }

  Future<void> downloadNewVersion() async {
    final path = '${_tempDir.path}\\RevisionTool-Setup.exe';
    final assetList = List<Map<String, dynamic>>.from(
      _data['assets'] as List<dynamic>,
    );
    final Response<dynamic> download = await _dio.download(
      assetList.first['browser_download_url'] as String,
      path,
    );
    logger.i('New Revision Tool download status: ${download.statusMessage}');
  }

  Future<void> installUpdate() async {
    final installerPath = '${_tempDir.path}\\RevisionTool-Setup.exe';
    final String appPath = Platform.resolvedExecutable;
    final scriptPath = '${_tempDir.path}\\revitool_update.cmd';

    File(scriptPath).writeAsStringSync(
      '@echo off\r\n'
      '"$installerPath" /VERYSILENT /TASKS="desktopicon"\r\n'
      'start "" "$appPath"\r\n',
    );

    await Process.start(scriptPath, [], mode: ProcessStartMode.detached);
    exit(0);
  }

  String get _currentAppVersion =>
      const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  String? get _latestTagName {
    if (_data.isEmpty) {
      logger.e('The fetched API data variable is empty');
      return null;
    }
    final String? tagName = _data['tag_name']?.toString();
    if (tagName == null || tagName.isEmpty) {
      logger.e('Latest release tag_name is missing');
      return null;
    }
    return tagName;
  }

  static int _toSortableInt(String version) {
    final _ParsedVersion parsed = _ParsedVersion.parse(version);
    final int major = parsed.core.isNotEmpty ? parsed.core[0] : 0;
    final int minor = parsed.core.length > 1 ? parsed.core[1] : 0;
    final int patch = parsed.core.length > 2 ? parsed.core[2] : 0;
    return (major * 1000000) + (minor * 1000) + patch;
  }
}

class _ParsedVersion {
  _ParsedVersion({required this.core, required this.preRelease});

  final List<int> core;
  final List<String> preRelease;

  static _ParsedVersion parse(String rawVersion) {
    final String trimmed = rawVersion.trim();
    final String withoutPrefix =
        trimmed.startsWith('v') || trimmed.startsWith('V')
        ? trimmed.substring(1)
        : trimmed;
    final String withoutBuild = withoutPrefix.split('+').first;
    final List<String> splitPre = withoutBuild.split('-');
    final String corePart = splitPre.first;
    final String prePart = splitPre.length > 1
        ? splitPre.sublist(1).join('-')
        : '';

    final List<int> core = corePart.split('.').map((String segment) {
      final Match? digits = RegExp(r'\d+').firstMatch(segment);
      if (digits == null) return 0;
      return int.tryParse(digits.group(0)!) ?? 0;
    }).toList();
    if (core.isEmpty) core.add(0);

    final List<String> preRelease = prePart.isEmpty
        ? <String>[]
        : prePart.split('.').where((String part) => part.isNotEmpty).toList();

    return _ParsedVersion(core: core, preRelease: preRelease);
  }
}
