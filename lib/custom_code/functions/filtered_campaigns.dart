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

List<CampaignsRecord> filteredCampaigns(
  List<CampaignsRecord> campaigns,
  String searchQuery,
) {
  final all = campaigns;
  final q = searchQuery.trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((c) {
    final name = c.name.toLowerCase();
    final status = c.status.toLowerCase();
    final rawDate = c.createdAt.toLowerCase();
    String formattedDate = '';
    final parsedDate = DateTime.tryParse(c.createdAt);
    if (parsedDate != null) {
      formattedDate = DateFormat('MMM d, yyyy').format(parsedDate).toLowerCase();
    }
    return name.contains(q) ||
        status.contains(q) ||
        rawDate.contains(q) ||
        (formattedDate.isNotEmpty && formattedDate.contains(q));
  }).toList();
}
