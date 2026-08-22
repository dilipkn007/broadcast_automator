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

double progressPercent(
  List<CampaignsRecord> campaigns,
  String campaignId,
) {
  final c = campaigns
      .where((c) => c.id == (campaignId ?? ""))
      .firstOrNull;
  if (c == null) return 0.0;
  final total = c.contactCount;
  if (total == 0) return 0.0;
  return (c.currentIndex / total).clamp(0.0, 1.0);
}
