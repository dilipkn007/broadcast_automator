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

dynamic currentCampaign(
  List<CampaignsRecord> campaigns,
  String campaignId,
) {
  final c = campaigns
      .where((c) => c.id == (campaignId ?? ""))
      .firstOrNull;
  if (c == null) return {};
  return {
    "name": c.name,
    "status": c.status,
    "total": c.contactCount,
    "currentIndex": c.currentIndex,
  };
}
