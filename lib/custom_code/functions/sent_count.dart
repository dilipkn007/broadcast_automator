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

int sentCount(
  List<ContactsRecord> contacts,
  String campaignId,
) {
  return campaignContacts(contacts, campaignId)
      .where((c) => c.status == "Sent")
      .toList()
      .length;
}
