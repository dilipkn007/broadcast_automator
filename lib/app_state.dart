import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '/backend/backend.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  late SharedPreferences prefs;

  // ---------------------------------------------------------------------------
  // 1. APP STARTUP: DEVICE ID INITIALIZATION & LOCAL STORAGE PERSISTENCE
  // Checks SharedPreferences for 'user_device_uuid'. If missing, generates a
  // new random UUID v4 and saves it permanently under 'user_device_uuid'.
  // ---------------------------------------------------------------------------
  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _userDeviceUuid = prefs.getString('user_device_uuid') ?? '';
    if (_userDeviceUuid.isEmpty) {
      _userDeviceUuid = const Uuid().v4();
      await prefs.setString('user_device_uuid', _userDeviceUuid);
    }
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _userDeviceUuid = '';
  String get userDeviceUuid => _userDeviceUuid;
  set userDeviceUuid(String value) {
    _userDeviceUuid = value;
    prefs.setString('user_device_uuid', value);
  }

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  set searchQuery(String value) {
    _searchQuery = value;
  }

  String _activeCampaignId = '';
  String get activeCampaignId => _activeCampaignId;
  set activeCampaignId(String value) {
    _activeCampaignId = value;
  }
}

