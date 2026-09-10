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

dynamic campaignStats(
  List<CampaignsRecord> campaigns,
  List<ContactsRecord> contacts,
  String campaignId,
) {
  final targetId = campaignId.trim();
  final all_contacts = targetId.isEmpty
      ? contacts
      : contacts.where((ct) => ct.campaignId == targetId).toList();
  final sent = all_contacts
      .where((ct) => ct.status.trim().toLowerCase() == 'sent')
      .length;
  final failed = all_contacts
      .where((ct) => ct.status.trim().toLowerCase() == 'failed')
      .length;
  final skipped = all_contacts
      .where((ct) => ct.status.trim().toLowerCase() == 'skipped')
      .length;
  return {
    "total": all_contacts.length.toString(),
    "sent": sent.toString(),
    "failed": failed.toString(),
    "skipped": skipped.toString(),
  };
}
