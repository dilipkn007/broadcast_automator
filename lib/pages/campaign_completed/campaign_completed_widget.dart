import '/backend/backend.dart';
import '/components/button/button_widget.dart';
import '/components/create_campaign_from_history_sheet.dart';
import '/components/report_stat_card/report_stat_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/native_bridge.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'campaign_completed_model.dart';
export 'campaign_completed_model.dart';

class CampaignCompletedWidget extends StatefulWidget {
  const CampaignCompletedWidget({
    super.key,
    required this.campaignId,
  });

  final String? campaignId;

  static String routeName = 'CampaignCompleted';
  static String routePath = '/campaignCompleted';

  @override
  State<CampaignCompletedWidget> createState() =>
      _CampaignCompletedWidgetState();
}

class _CampaignCompletedWidgetState extends State<CampaignCompletedWidget>
    with WidgetsBindingObserver {
  late CampaignCompletedModel _model;
  String _resolvedCampaignId = '';
  Map<String, dynamic>? _nativeReport;
  CampaignsRecord? _campaignRecord;
  List<Map<String, String>> _campaignAttachments = [];

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = createModel(context, () => CampaignCompletedModel());
    _resolvedCampaignId = widget.campaignId?.trim() ?? '';
    _loadReportData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadReportData();
    }
  }

  Future<void> _loadReportData() async {
    try {
      final rep = await NativeBridge.getBroadcastReport();
      if (!mounted) return;
      setState(() {
        _nativeReport = rep;
        if (_resolvedCampaignId.isEmpty) {
          final cid = rep['campaignId']?.toString().trim() ?? '';
          if (cid.isNotEmpty) {
            _resolvedCampaignId = cid;
          }
        }
      });
      if (_resolvedCampaignId.isNotEmpty) {
        final list = await queryCampaignsRecordOnce(
          queryBuilder: (q) => q.where('id', isEqualTo: _resolvedCampaignId),
          singleRecord: true,
        );
        if (list.isNotEmpty && mounted) {
          setState(() {
            _campaignRecord = list.first;
          });
        }
        final attList = await queryAttachmentsRecordOnce(
          queryBuilder: (q) =>
              q.where('campaign_id', isEqualTo: _resolvedCampaignId),
        );
        if (mounted) {
          setState(() {
            _campaignAttachments = attList.map((a) {
              final path = a.sourceUrl;
              return <String, String>{
                'id': a.id,
                'path': path,
                'mimeType': a.type,
                'name': path.split('/').last,
              };
            }).toList();
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();
    super.dispose();
  }

  Future<void> _retryFailedBroadcast(
      List<Map<String, dynamic>> failedContacts) async {
    if (failedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No failed contacts to retry.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.replay_rounded,
                color: FlutterFlowTheme.of(context).error),
            const SizedBox(width: 8.0),
            Text(
              'Retry Failed Messages',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          ],
        ),
        content: Text(
          'Do you want to retry sending messages to ${failedContacts.length} failed contact(s)?',
          style: GoogleFonts.inter(fontSize: 14.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Retry Now',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 1. Reset failed contacts in DB to 'Pending'
    for (final fc in failedContacts) {
      final id = fc['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        await localDb.update('contacts', {'status': 'Pending'},
            where: 'id = ?', whereArgs: [id]);
      }
    }
    localDb.notifyTableChanged('contacts');

    // 2. Prepare parameters
    final campaign = _campaignRecord;
    final message = campaign?.messageBody ?? '';
    final campaignName =
        campaign?.name.isNotEmpty == true ? campaign!.name : 'Broadcast Retry';
    final delaySeconds = campaign?.delaySeconds ?? 6;
    final randomizeDelay = campaign?.randomizeDelay ?? true;
    final skipInvalid = campaign?.skipInvalid ?? true;
    final autoRetry = campaign?.autoRetry ?? false;

    await NativeBridge.saveJob(
      campaignId: _resolvedCampaignId,
      campaignName: campaignName,
      message: message,
      delaySeconds: delaySeconds,
      preSendDelaySeconds: 2,
      randomizeDelay: randomizeDelay,
      autoRetry: autoRetry,
      skipInvalid: skipInvalid,
      contacts: failedContacts.map((c) => {
            'id': (c['id'] ?? '').toString(),
            'name': (c['name'] ?? '').toString(),
            'phone': (c['phone'] ?? '').toString(),
            if (c['extra_fields'] != null)
              'extraFields': c['extra_fields']
            else if (c['extraFields'] != null)
              'extraFields': c['extraFields'],
          }).toList(),
      attachments: _campaignAttachments,
      attachmentPath: _campaignAttachments.isNotEmpty
          ? _campaignAttachments.first['path']
          : null,
      attachmentMime: _campaignAttachments.isNotEmpty
          ? _campaignAttachments.first['mimeType']
          : null,
    );

    // 3. Start broadcast
    final started = await NativeBridge.startBroadcast(_resolvedCampaignId);
    if (started['started'] != true) {
      if (!mounted) return;
      if (started['accessibilityEnabled'] == false) {
        await NativeBridge.openAccessibilitySettings();
        showSnackbar(context,
            'Enable the "WhatsApp Broadcast Automator" accessibility service, then retry.');
      } else if (started['overlayPermission'] == false) {
        await NativeBridge.openOverlaySettings();
        showSnackbar(context,
            'Allow "Display over other apps" so the progress overlay can appear on WhatsApp.');
      } else {
        showSnackbar(context, 'Could not start retry: ${started['error']}');
      }
      return;
    }

    if (!mounted) return;
    context.goNamed(
      SendingProgressOverlayWidget.routeName,
      queryParameters: {
        'campaignId': serializeParam(
          _resolvedCampaignId,
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    return '${s}s';
  }

  void _openDetailedReportModal({
    required BuildContext context,
    required String campaignId,
    required List<Map<String, dynamic>> contacts,
    required int total,
    required int sent,
    required int failed,
    required int skipped,
    required String messageBody,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DetailedReportSheet(
          campaignId: campaignId,
          contacts: contacts,
          total: total,
          sent: sent,
          failed: failed,
          skipped: skipped,
          messageBody: messageBody,
          onRetryFailed: (failedList) => _retryFailedBroadcast(failedList),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: StreamBuilder<List<ContactsRecord>>(
            stream: queryContactsRecord(
              queryBuilder: (q) => _resolvedCampaignId.isNotEmpty
                  ? q.where('campaign_id', isEqualTo: _resolvedCampaignId)
                  : q,
            ),
            builder: (context, snapshot) {
              final dbContacts = snapshot.data ?? [];
              final hasDbContacts = dbContacts.isNotEmpty;

              // Parse contact stats from DB
              int total = 0;
              int sent = 0;
              int failed = 0;
              int skipped = 0;

              List<Map<String, dynamic>> unifiedContacts = [];

              if (hasDbContacts) {
                total = dbContacts.length;
                sent = dbContacts
                    .where((c) => c.status.trim().toLowerCase() == 'sent')
                    .length;
                failed = dbContacts
                    .where((c) => c.status.trim().toLowerCase() == 'failed')
                    .length;
                skipped = dbContacts
                    .where((c) => c.status.trim().toLowerCase() == 'skipped')
                    .length;

                unifiedContacts = dbContacts
                    .map((c) => {
                          'id': c.id,
                          'name': c.name.isEmpty ? 'Unknown' : c.name,
                          'phone': c.phone,
                          'status': c.status.isEmpty ? 'Pending' : c.status,
                          'extra_fields': c.extraFields,
                        })
                    .toList();
              }

              // Resilient fallback to native report if Supabase query returned 0 or un-synced
              if (_nativeReport != null) {
                final nTotal = (_nativeReport!['total'] as num?)?.toInt() ?? 0;
                final nSent = (_nativeReport!['sent'] as num?)?.toInt() ?? 0;
                final nFailed = (_nativeReport!['failed'] as num?)?.toInt() ?? 0;
                final nSkipped = (_nativeReport!['skipped'] as num?)?.toInt() ?? 0;

                if (total == 0 && nTotal > 0) {
                  total = nTotal;
                }
                if (sent == 0 && nSent > 0) {
                  sent = nSent;
                }
                if (failed == 0 && nFailed > 0) {
                  failed = nFailed;
                }
                if (skipped == 0 && nSkipped > 0) {
                  skipped = nSkipped;
                }

                if (unifiedContacts.isEmpty) {
                  final rawContacts = _nativeReport!['contacts'] as List?;
                  if (rawContacts != null) {
                    unifiedContacts = rawContacts
                        .map((c) => {
                              'id': (c['id'] ?? '').toString(),
                              'name': (c['name'] ?? 'Unknown').toString(),
                              'phone': (c['phone'] ?? '').toString(),
                              'status': (c['status'] ?? 'Sent').toString(),
                              'extra_fields':
                                  c['extraFields'] ?? c['extra_fields'] ?? {},
                            })
                        .toList();
                  }
                }
              }

              // Calculate duration
              int durationSec =
                  (_nativeReport?['durationSeconds'] as num?)?.toInt() ?? 0;
              if (durationSec <= 0 && total > 0) {
                durationSec = (sent + failed + skipped) * 6;
              }
              final durationText = _formatDuration(durationSec);

              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Celebration Header
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                24.0, 32.0, 24.0, 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 140.0,
                                  height: 140.0,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 110.0,
                                        height: 110.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .success
                                              .withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 80.0,
                                            height: 80.0,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context)
                                                  .success,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: FlutterFlowTheme.of(context)
                                                      .success
                                                      .withOpacity(0.4),
                                                  blurRadius: 18.0,
                                                  offset: const Offset(0, 8),
                                                )
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 48.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Lottie.network(
                                        'https://dimg.dreamflow.cloud/v1/lottie/celebration+success+checkmark+green+animation',
                                        width: 140.0,
                                        height: 140.0,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const SizedBox(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  'Broadcast Completed',
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        lineHeight: 1.25,
                                      ),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  'Your messages have been processed and dispatched.',
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        letterSpacing: 0.0,
                                        lineHeight: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom Summary Card
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28.0),
                                topRight: Radius.circular(28.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12.0,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  24.0, 28.0, 24.0, 32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Section Header + Duration Pill
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Campaign Summary',
                                        style: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .surfaceVariant,
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 1.0,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 5.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              size: 14.0,
                                            ),
                                            const SizedBox(width: 4.0),
                                            Text(
                                              'Duration: $durationText',
                                              style: FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    fontSize: 11.5,
                                                    letterSpacing: 0.0,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20.0),

                                  // 2x2 Stat Cards Grid
                                  Row(
                                    children: [
                                      Expanded(
                                        child: wrapWithModel(
                                          model: _model.reportStatCardModel1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ReportStatCardWidget(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            icon: const Icon(
                                              Icons.group_rounded,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                            label: 'Total Contacts',
                                            value: '$total',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: wrapWithModel(
                                          model: _model.reportStatCardModel2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ReportStatCardWidget(
                                            color: FlutterFlowTheme.of(context)
                                                .success,
                                            icon: const Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                            label: 'Successfully Sent',
                                            value: '$sent',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: wrapWithModel(
                                          model: _model.reportStatCardModel3,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ReportStatCardWidget(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            icon: const Icon(
                                              Icons.error_rounded,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                            label: 'Failed',
                                            value: '$failed',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: wrapWithModel(
                                          model: _model.reportStatCardModel4,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ReportStatCardWidget(
                                            color: FlutterFlowTheme.of(context)
                                                .warning,
                                            icon: const Icon(
                                              Icons.block_rounded,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                            label: 'Skipped',
                                            value: '$skipped',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28.0),

                                  // Action Buttons
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (failed > 0) ...[
                                        // Retry Failed Messages Button
                                        InkWell(
                                          splashColor: Colors.transparent,
                                          focusColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          onTap: () {
                                            final failedList = unifiedContacts
                                                .where((c) =>
                                                    (c['status'] ?? '')
                                                        .toString()
                                                        .trim()
                                                        .toLowerCase() ==
                                                    'failed')
                                                .toList();
                                            _retryFailedBroadcast(failedList);
                                          },
                                          child: wrapWithModel(
                                            model: _model.retryButtonModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: ButtonWidget(
                                              icon: const Icon(
                                                Icons.replay_rounded,
                                                color: Colors.white,
                                                size: 20.0,
                                              ),
                                              iconPresent: true,
                                              iconEndPresent: false,
                                              content:
                                                  'Retry Failed Messages ($failed)',
                                              variant: 'destructive',
                                              size: 'large',
                                              fullWidth: true,
                                              loading: false,
                                              disabled: false,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14.0),
                                      ],

                                      // View Detailed Report Button
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          _openDetailedReportModal(
                                            context: context,
                                            campaignId: _resolvedCampaignId,
                                            contacts: unifiedContacts,
                                            total: total,
                                            sent: sent,
                                            failed: failed,
                                            skipped: skipped,
                                            messageBody:
                                                _campaignRecord?.messageBody ?? '',
                                          );
                                        },
                                        child: wrapWithModel(
                                          model: _model.buttonModel1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ButtonWidget(
                                            icon: Icon(
                                              Icons.assessment_rounded,
                                              color: FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              size: 22.0,
                                            ),
                                            iconPresent: true,
                                            iconEndPresent: false,
                                            content: 'View Detailed Report',
                                            variant: 'outline',
                                            size: 'large',
                                            fullWidth: true,
                                            loading: false,
                                            disabled: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14.0),

                                      // Create Campaign with These Contacts Button
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          showCreateCampaignFromHistorySheet(
                                            context,
                                            sourceCampaignId:
                                                _resolvedCampaignId,
                                            preloadedContacts: unifiedContacts
                                                .map((c) => {
                                                      'id': (c['id'] ?? '')
                                                          .toString(),
                                                      'name': (c['name'] ?? '')
                                                          .toString(),
                                                      'phone': (c['phone'] ?? '')
                                                          .toString(),
                                                      'status':
                                                          (c['status'] ?? '')
                                                              .toString(),
                                                    })
                                                .toList(),
                                          );
                                        },
                                        child: wrapWithModel(
                                          model: _model.buttonModel4,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ButtonWidget(
                                            icon: const Icon(
                                              Icons.person_add_alt_1_rounded,
                                              color: Colors.white,
                                              size: 20.0,
                                            ),
                                            iconPresent: true,
                                            iconEndPresent: false,
                                            content: 'Create Campaign with Contacts',
                                            variant: 'primary',
                                            size: 'large',
                                            fullWidth: true,
                                            loading: false,
                                            disabled: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14.0),

                                      // Start New Broadcast Button
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          context.pushNamed(
                                              CreateBroadcastWidget.routeName);
                                        },
                                        child: wrapWithModel(
                                          model: _model.buttonModel2,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ButtonWidget(
                                            icon: Icon(
                                              Icons.add_rounded,
                                              color: FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              size: 22.0,
                                            ),
                                            iconPresent: true,
                                            iconEndPresent: false,
                                            content: 'Start New Broadcast',
                                            variant: 'outline',
                                            size: 'large',
                                            fullWidth: true,
                                            loading: false,
                                            disabled: false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14.0),

                                      // Back to Home Button
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          context.goNamed(
                                              BroadcastListsWidget.routeName);
                                        },
                                        child: wrapWithModel(
                                          model: _model.buttonModel3,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: ButtonWidget(
                                            iconPresent: false,
                                            iconEndPresent: false,
                                            content: 'Back to Home',
                                            variant: 'ghost',
                                            size: 'medium',
                                            fullWidth: true,
                                            loading: false,
                                            disabled: false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Interactive modal bottom sheet presenting contact-by-contact delivery breakdown.
class _DetailedReportSheet extends StatefulWidget {
  const _DetailedReportSheet({
    required this.campaignId,
    required this.contacts,
    required this.total,
    required this.sent,
    required this.failed,
    required this.skipped,
    this.messageBody = '',
    this.onRetryFailed,
  });

  final String campaignId;
  final List<Map<String, dynamic>> contacts;
  final int total;
  final int sent;
  final int failed;
  final int skipped;
  final String messageBody;
  final void Function(List<Map<String, dynamic>> failedContacts)? onRetryFailed;

  @override
  State<_DetailedReportSheet> createState() => _DetailedReportSheetState();
}

class _DetailedReportSheetState extends State<_DetailedReportSheet> {
  String _selectedFilter = 'all'; // all, sent, failed, skipped
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late List<Map<String, dynamic>> _sheetContacts;
  StreamSubscription? _dbSubscription;

  @override
  void initState() {
    super.initState();
    _sheetContacts = List.from(widget.contacts);
    _dbSubscription = localDb.onTableChange.listen((table) {
      if (table == 'contacts' && mounted) {
        _refreshContacts();
      }
    });
  }

  Future<void> _refreshContacts() async {
    if (widget.campaignId.isEmpty) return;
    try {
      final updated = await queryContactsRecordOnce(
        queryBuilder: (q) =>
            q.where('campaign_id', isEqualTo: widget.campaignId),
      );
      if (updated.isNotEmpty && mounted) {
        setState(() {
          _sheetContacts = updated
              .map((c) => {
                    'id': c.id,
                    'name': c.name.isEmpty ? 'Unknown' : c.name,
                    'phone': c.phone,
                    'status': c.status.isEmpty ? 'Pending' : c.status,
                    'extra_fields': c.extraFields,
                  })
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _sendManualMessage(Map<String, dynamic> c) async {
    final phone = (c['phone'] ?? '').toString().trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact has no phone number.')),
      );
      return;
    }

    final name = (c['name'] ?? '').toString().trim();
    final extraFields = <String, String>{};
    if (c['extra_fields'] is Map) {
      (c['extra_fields'] as Map).forEach((k, v) {
        if (k != null && v != null) extraFields[k.toString()] = v.toString();
      });
    } else if (c['extraFields'] is Map) {
      (c['extraFields'] as Map).forEach((k, v) {
        if (k != null && v != null) extraFields[k.toString()] = v.toString();
      });
    }

    final templateValues = <String, String>{
      'Name': name.isNotEmpty ? name : 'Friend',
      'Number': phone,
      'Phone': phone,
      ...extraFields,
    };

    final template =
        widget.messageBody.isNotEmpty ? widget.messageBody : 'Hello {{Name}}';
    final resolved = resolveMessageTemplate(template, templateValues);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18.0),
            SizedBox(width: 8.0),
            Expanded(
              child: Text(
                  'Opening WhatsApp... Tap Send to dispatch and return automatically.'),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
    );

    final contactId = (c['id'] ?? '').toString();
    final ok = await NativeBridge.openManualWhatsAppChat(
      phone: phone,
      message: resolved,
      contactId: contactId,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open WhatsApp for this contact.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final totalCount = _sheetContacts.length;
    final sentCount = _sheetContacts
        .where((c) =>
            (c['status'] ?? '').toString().trim().toLowerCase() == 'sent')
        .length;
    final failedCount = _sheetContacts
        .where((c) =>
            (c['status'] ?? '').toString().trim().toLowerCase() == 'failed')
        .length;
    final skippedCount = _sheetContacts
        .where((c) =>
            (c['status'] ?? '').toString().trim().toLowerCase() == 'skipped')
        .length;

    final filteredContacts = _sheetContacts.where((c) {
      final status = (c['status'] ?? '').toString().trim().toLowerCase();
      if (_selectedFilter == 'sent' && status != 'sent') return false;
      if (_selectedFilter == 'failed' && status != 'failed') return false;
      if (_selectedFilter == 'skipped' && status != 'skipped') return false;

      if (_searchQuery.isNotEmpty) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12.0),
          Center(
            child: Container(
              width: 44.0,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.alternate,
                borderRadius: BorderRadius.circular(999.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Delivery Report',
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.primaryText,
                        fontSize: 19.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '$totalCount total recipients',
                      style: GoogleFonts.inter(
                        color: theme.secondaryText,
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.secondaryText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 44.0,
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: theme.alternate, width: 1.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: theme.secondaryText, size: 20.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      style: GoogleFonts.inter(
                        color: theme.primaryText,
                        fontSize: 14.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by contact name or phone...',
                        hintStyle: GoogleFonts.inter(
                          color: theme.secondaryText,
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.clear_rounded,
                          color: theme.secondaryText, size: 18.0),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12.0),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildFilterChip('all', 'All ($totalCount)', theme.primaryText),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                    'sent', 'Sent ($sentCount)', theme.success,
                    icon: Icons.check_circle_rounded),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                    'failed', 'Failed ($failedCount)', theme.error,
                    icon: Icons.error_rounded),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                    'skipped', 'Skipped ($skippedCount)', theme.warning,
                    icon: Icons.block_rounded),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          Divider(color: theme.alternate, height: 1.0),

          // Contacts List
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search_rounded,
                            size: 48.0,
                            color: theme.secondaryText.withOpacity(0.5)),
                        const SizedBox(height: 8.0),
                        Text(
                          'No contacts found',
                          style: GoogleFonts.inter(
                            color: theme.secondaryText,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 12.0),
                    itemCount: filteredContacts.length,
                    separatorBuilder: (_, __) => Divider(
                        color: theme.alternate.withOpacity(0.5), height: 1.0),
                    itemBuilder: (context, index) {
                      final c = filteredContacts[index];
                      final name = (c['name'] ?? 'Unknown').toString();
                      final phone = (c['phone'] ?? '').toString();
                      final status =
                          (c['status'] ?? 'Pending').toString().trim();
                      final stLower = status.toLowerCase();

                      Color statusColor;
                      Color statusBg;
                      IconData statusIcon;

                      if (stLower == 'sent') {
                        statusColor = theme.success;
                        statusBg = theme.success.withOpacity(0.12);
                        statusIcon = Icons.check_circle_rounded;
                      } else if (stLower == 'failed') {
                        statusColor = theme.error;
                        statusBg = theme.error.withOpacity(0.12);
                        statusIcon = Icons.error_rounded;
                      } else if (stLower == 'skipped') {
                        statusColor = theme.warning;
                        statusBg = theme.warning.withOpacity(0.12);
                        statusIcon = Icons.block_rounded;
                      } else {
                        statusColor = theme.secondaryText;
                        statusBg = theme.surfaceVariant;
                        statusIcon = Icons.hourglass_bottom_rounded;
                      }

                      final initial =
                          name.isNotEmpty ? name[0].toUpperCase() : '#';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: theme.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: GoogleFonts.plusJakartaSans(
                                  color: theme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),

                            // Name & Phone
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: theme.primaryText,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    phone,
                                    style: GoogleFonts.inter(
                                      color: theme.secondaryText,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status Badge
                            Container(
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 4.5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 13.0, color: statusColor),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    status,
                                    style: GoogleFonts.inter(
                                      color: statusColor,
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Manual Pre-filled WhatsApp Send Button ("->")
                            if (stLower == 'failed') ...[
                              const SizedBox(width: 8.0),
                              Material(
                                color:
                                    const Color(0xFF25D366).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20.0),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20.0),
                                  onTap: () => _sendManualMessage(c),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF25D366)
                                            .withOpacity(0.4),
                                        width: 1.0,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(20.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10.0, vertical: 4.5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Send',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF128C7E),
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 4.0),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 14.0,
                                          color: Color(0xFF128C7E),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action
          if (widget.campaignId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (failedCount > 0) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.onRetryFailed != null) {
                            final failedList = _sheetContacts
                                .where((c) =>
                                    (c['status'] ?? '')
                                        .toString()
                                        .trim()
                                        .toLowerCase() ==
                                    'failed')
                                .toList();
                            widget.onRetryFailed!(failedList);
                          }
                        },
                        icon: const Icon(Icons.replay_rounded, size: 18.0),
                        label: Text('Retry Failed Messages ($failedCount)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showCreateCampaignFromHistorySheet(
                          context,
                          sourceCampaignId: widget.campaignId,
                          preloadedContacts: (filteredContacts.isNotEmpty
                                  ? filteredContacts
                                  : _sheetContacts)
                              .map((c) => {
                                    'id': (c['id'] ?? '').toString(),
                                    'name': (c['name'] ?? '').toString(),
                                    'phone': (c['phone'] ?? '').toString(),
                                    'status': (c['status'] ?? '').toString(),
                                  })
                              .toList(),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded,
                          size: 18.0),
                      label: Text(
                        _selectedFilter == 'all'
                            ? 'Create Campaign with Contacts'
                            : 'Create Campaign with ${_selectedFilter.toUpperCase()} Contacts (${filteredContacts.length})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.pushNamed(
                          BroadcastDetailsWidget.routeName,
                          queryParameters: {
                            'campaignId': serializeParam(
                              widget.campaignId,
                              ParamType.String,
                            ),
                          }.withoutNulls,
                        );
                      },
                      icon: const Icon(Icons.history_rounded, size: 18.0),
                      label: const Text('Open Historical Campaign Record'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryText,
                        side: BorderSide(color: theme.alternate, width: 1.0),
                        padding: const EdgeInsets.symmetric(vertical: 13.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color activeColor,
      {IconData? icon}) {
    final theme = FlutterFlowTheme.of(context);
    final isSelected = _selectedFilter == key;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon,
                size: 14.0,
                color: isSelected ? Colors.white : activeColor),
            const SizedBox(width: 4.0),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: theme.surfaceVariant,
      side: BorderSide(
        color: isSelected ? activeColor : theme.alternate,
        width: 1.0,
      ),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : theme.primaryText,
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = key);
        }
      },
    );
  }
}
