import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/flutter_flow/custom_functions.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/uploaded_file.dart';
import '/backend/backend.dart';

dynamic currentContact(
  List<ContactsRecord> contacts,
  String campaignId,
) {
  final list = campaignContacts(contacts, campaignId);
  if (list.isEmpty) return {};
  final c = list.firstWhere(
    (c) => c.status == "Pending" || c.status == "Sending",
    orElse: () => list.first,
  );
  final name = c.name.trim().isEmpty ? 'Unknown' : c.name.trim();
  return {"name": name, "initials": name.substring(0, 1)};
}
