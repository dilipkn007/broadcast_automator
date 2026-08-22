import 'dart:async';
import '/index.dart';
import '/backend/backend.dart';
import '/components/button/button_widget.dart';
import '/components/progress_stat_item/progress_stat_item_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '/services/native_bridge.dart';
import 'sending_progress_overlay_model.dart';
export 'sending_progress_overlay_model.dart';

class SendingProgressOverlayWidget extends StatefulWidget {
  const SendingProgressOverlayWidget({
    super.key,
    required this.campaignId,
  });

  final String? campaignId;

  static String routeName = 'SendingProgressOverlay';
  static String routePath = '/sendingProgressOverlay';

  @override
  State<SendingProgressOverlayWidget> createState() =>
      _SendingProgressOverlayWidgetState();
}

class _SendingProgressOverlayWidgetState
    extends State<SendingProgressOverlayWidget> {
  late SendingProgressOverlayModel _model;
  Timer? _statusTimer;
  bool _hasNavigated = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SendingProgressOverlayModel());
    _startStatusCheck();
  }

  void _startStatusCheck() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || _hasNavigated) {
        timer.cancel();
        return;
      }
      final status = await NativeBridge.getBroadcastStatus();
      final bool running = status['running'] == true;
      final int currentIndex = (status['currentIndex'] as num?)?.toInt() ?? 0;
      final int total = (status['total'] as num?)?.toInt() ?? 0;

      if (!running && total > 0 && currentIndex >= total) {
        _navigateToCompleted();
      }
    });
  }

  void _navigateToCompleted() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _statusTimer?.cancel();
    _statusTimer = null;
    context.goNamed(
      CampaignCompletedWidget.routeName,
      queryParameters: {
        'campaignId': serializeParam(
          widget.campaignId,
          ParamType.String,
        ),
      }.withoutNulls,
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _model.dispose();

    super.dispose();
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
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 0.0,
                height: 0.0,
              ),
              Container(
                width: 0.0,
                height: 0.0,
              ),
              Container(
                width: 0.0,
                height: 0.0,
              ),
              Expanded(
                child: Stack(
                  alignment: AlignmentDirectional(-1.0, -1.0),
                  children: [
                    Align(
                      alignment: AlignmentDirectional(0.0, 1.0),
                      child: Container(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 16.0),
                                  child: Container(
                                    child: Container(
                                      width: 40.0,
                                      height: 4.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        borderRadius:
                                            BorderRadius.circular(9999.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(28.0),
                                    shape: BoxShape.rectangle,
                                    border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: StreamBuilder<List<CampaignsRecord>>(
                                      stream: queryCampaignsRecord(),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50,
                                              height: 50,
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        List<CampaignsRecord>
                                            containerPaddingCampaignsRecordList =
                                            snapshot.data!;

                                        return Container(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        getJsonField(
                                                                  functions.currentCampaign(
                                                                      containerPaddingCampaignsRecordList
                                                                          .toList(),
                                                                      widget!
                                                                          .campaignId!),
                                                                  r'''$.name''',
                                                                ) !=
                                                                null
                                                            ? getJsonField(
                                                                functions.currentCampaign(
                                                                    containerPaddingCampaignsRecordList
                                                                        .toList(),
                                                                    widget!
                                                                        .campaignId!),
                                                                r'''$.name''',
                                                              ).toString()
                                                            : '',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .titleMedium
                                                            .override(
                                                              font: GoogleFonts
                                                                  .plusJakartaSans(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                              ),
                                                              letterSpacing:
                                                                  0.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleMedium
                                                                      .fontStyle,
                                                              lineHeight: 1.4,
                                                            ),
                                                      ),
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            width: 8.0,
                                                            height: 8.0,
                                                            decoration:
                                                                BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                          ),
                                                          Text(
                                                            _model.isPaused ==
                                                                    true
                                                                ? 'Paused'
                                                                : 'Sending in progress...',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .labelSmall
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.2,
                                                                ),
                                                          ),
                                                        ].divide(SizedBox(
                                                            width: 4.0)),
                                                      ),
                                                    ].divide(
                                                        SizedBox(height: 4.0)),
                                                  ),
                                                  FlutterFlowIconButton(
                                                    borderRadius: 9999.0,
                                                    buttonSize: 40.0,
                                                    fillColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .surfaceVariant,
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      size: 24.0,
                                                    ),
                                                    onPressed: () async {
                                                      context.pop();
                                                    },
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        functions.progressLabel(
                                                            containerPaddingCampaignsRecordList
                                                                .toList(),
                                                            widget!
                                                                .campaignId!),
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelLarge
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .onSurface,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.3,
                                                                ),
                                                      ),
                                                      Text(
                                                        '${getJsonField(
                                                              functions.currentCampaign(
                                                                  containerPaddingCampaignsRecordList
                                                                      .toList(),
                                                                  widget!
                                                                      .campaignId!),
                                                              r'''$.currentIndex''',
                                                            ) != null ? getJsonField(
                                                            functions.currentCampaign(
                                                                containerPaddingCampaignsRecordList
                                                                    .toList(),
                                                                widget!
                                                                    .campaignId!),
                                                            r'''$.currentIndex''',
                                                          ).toString() : '0'} / ${getJsonField(
                                                              functions.currentCampaign(
                                                                  containerPaddingCampaignsRecordList
                                                                      .toList(),
                                                                  widget!
                                                                      .campaignId!),
                                                              r'''$.total''',
                                                            ) != null ? getJsonField(
                                                            functions.currentCampaign(
                                                                containerPaddingCampaignsRecordList
                                                                    .toList(),
                                                                widget!
                                                                    .campaignId!),
                                                            r'''$.total''',
                                                          ).toString() : '0'}',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .labelSmall
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelSmall
                                                                      .fontStyle,
                                                                  lineHeight:
                                                                      1.2,
                                                                ),
                                                      ),
                                                    ],
                                                  ),
                                                  LinearPercentIndicator(
                                                    percent: functions
                                                        .progressPercent(
                                                            containerPaddingCampaignsRecordList
                                                                .toList(),
                                                            widget!
                                                                .campaignId!),
                                                    lineHeight: 8.0,
                                                    animation: true,
                                                    animateFromLastPercent:
                                                        true,
                                                    progressColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                    backgroundColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .alternate,
                                                    barRadius:
                                                        Radius.circular(9999.0),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ].divide(SizedBox(height: 8.0)),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                  shape: BoxShape.rectangle,
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Container(
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          width: 40.0,
                                                          height: 40.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary10,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: StreamBuilder<
                                                              List<
                                                                  ContactsRecord>>(
                                                            stream:
                                                                queryContactsRecord(
                                                              queryBuilder: (q) =>
                                                                  q.where(
                                                                      'campaign_id',
                                                                      isEqualTo:
                                                                          widget
                                                                              .campaignId),
                                                            ),
                                                            builder: (context,
                                                                snapshot) {
                                                              // Customize what your widget looks like when it's loading.
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return Center(
                                                                  child:
                                                                      SizedBox(
                                                                    width: 50,
                                                                    height: 50,
                                                                    child:
                                                                        CircularProgressIndicator(),
                                                                  ),
                                                                );
                                                              }
                                                              List<ContactsRecord>
                                                                  avatarLabelContactsRecordList =
                                                                  snapshot
                                                                      .data!;

                                                              return Text(
                                                                getJsonField(
                                                                          functions.currentContact(
                                                                              avatarLabelContactsRecordList.toList(),
                                                                              widget!.campaignId!),
                                                                          r'''$.initials''',
                                                                        ) !=
                                                                        null
                                                                    ? getJsonField(
                                                                        functions.currentContact(
                                                                            avatarLabelContactsRecordList.toList(),
                                                                            widget!.campaignId!),
                                                                        r'''$.initials''',
                                                                      ).toString()
                                                                    : '',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                maxLines: 1,
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      fontSize:
                                                                          15.2,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelMedium
                                                                          .fontStyle,
                                                                      lineHeight:
                                                                          1.3,
                                                                    ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .clip,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        Expanded(
                                                          flex: 1,
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                'Current Contact',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .labelSmall
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .labelSmall
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .labelSmall
                                                                          .fontStyle,
                                                                      lineHeight:
                                                                          1.2,
                                                                    ),
                                                              ),
                                                              StreamBuilder<
                                                                  List<
                                                                      ContactsRecord>>(
                                                                stream:
                                                                    queryContactsRecord(
                                                                  queryBuilder:
                                                                      (q) =>
                                                                          q.where('campaign_id', isEqualTo: widget.campaignId),
                                                                ),
                                                                builder: (context,
                                                                    snapshot) {
                                                                  // Customize what your widget looks like when it's loading.
                                                                  if (!snapshot
                                                                      .hasData) {
                                                                    return Center(
                                                                      child:
                                                                          SizedBox(
                                                                        width:
                                                                            50,
                                                                        height:
                                                                            50,
                                                                        child:
                                                                            CircularProgressIndicator(),
                                                                      ),
                                                                    );
                                                                  }
                                                                  List<ContactsRecord>
                                                                      textContactsRecordList =
                                                                      snapshot
                                                                          .data!;

                                                                  return Text(
                                                                    getJsonField(
                                                                              functions.currentContact(textContactsRecordList.toList(), widget!.campaignId!),
                                                                              r'''$.name''',
                                                                            ) !=
                                                                            null
                                                                        ? getJsonField(
                                                                            functions.currentContact(textContactsRecordList.toList(),
                                                                                widget!.campaignId!),
                                                                            r'''$.name''',
                                                                          ).toString()
                                                                        : '',
                                                                    maxLines: 1,
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.inter(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                          lineHeight:
                                                                              1.5,
                                                                        ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  );
                                                                },
                                                              ),
                                                            ].divide(SizedBox(
                                                                height: 4.0)),
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .hourglass_bottom_rounded,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .onSurface,
                                                          size: 20.0,
                                                        ),
                                                      ].divide(SizedBox(
                                                          width: 16.0)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: StreamBuilder<
                                                        List<ContactsRecord>>(
                                                      stream:
                                                          queryContactsRecord(),
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return Center(
                                                            child: SizedBox(
                                                              width: 50,
                                                              height: 50,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          );
                                                        }
                                                        List<ContactsRecord>
                                                            progressStatItemContactsRecordList =
                                                            snapshot.data!;

                                                        return wrapWithModel(
                                                          model: _model
                                                              .progressStatItemModel1,
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              ProgressStatItemWidget(
                                                            label: 'Sent',
                                                            value: functions
                                                                .sentCount(
                                                                    progressStatItemContactsRecordList
                                                                        .toList(),
                                                                    widget!
                                                                        .campaignId!)
                                                                .toString(),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .success,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: StreamBuilder<
                                                        List<ContactsRecord>>(
                                                      stream:
                                                          queryContactsRecord(),
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return Center(
                                                            child: SizedBox(
                                                              width: 50,
                                                              height: 50,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          );
                                                        }
                                                        List<ContactsRecord>
                                                            progressStatItemContactsRecordList =
                                                            snapshot.data!;

                                                        return wrapWithModel(
                                                          model: _model
                                                              .progressStatItemModel2,
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              ProgressStatItemWidget(
                                                            label: 'Pending',
                                                            value: functions
                                                                .pendingCount(
                                                                    progressStatItemContactsRecordList
                                                                        .toList(),
                                                                    widget!
                                                                        .campaignId!)
                                                                .toString(),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: StreamBuilder<
                                                        List<ContactsRecord>>(
                                                      stream:
                                                          queryContactsRecord(),
                                                      builder:
                                                          (context, snapshot) {
                                                        // Customize what your widget looks like when it's loading.
                                                        if (!snapshot.hasData) {
                                                          return Center(
                                                            child: SizedBox(
                                                              width: 50,
                                                              height: 50,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          );
                                                        }
                                                        List<ContactsRecord>
                                                            progressStatItemContactsRecordList =
                                                            snapshot.data!;

                                                        return wrapWithModel(
                                                          model: _model
                                                              .progressStatItemModel3,
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              ProgressStatItemWidget(
                                                            label: 'Failed',
                                                            value: functions
                                                                .failedCount(
                                                                    progressStatItemContactsRecordList
                                                                        .toList(),
                                                                    widget!
                                                                        .campaignId!)
                                                                .toString(),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .error,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 16.0)),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.schedule_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .accent3,
                                                    size: 14.0,
                                                  ),
                                                  Text(
                                                    'Estimated Time Remaining: 12m 30s',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelSmall
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                          lineHeight: 1.2,
                                                        ),
                                                  ),
                                                ].divide(SizedBox(width: 4.0)),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    flex: 1,
                                                    child: InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        if (_model.isPaused ==
                                                            true) {
                                                          await NativeBridge
                                                              .resumeBroadcast();
                                                          _model.isPaused =
                                                              false;
                                                        } else {
                                                          await NativeBridge
                                                              .pauseBroadcast();
                                                          _model.isPaused = true;
                                                        }
                                                        safeSetState(() {});
                                                      },
                                                      child: wrapWithModel(
                                                        model:
                                                            _model.buttonModel1,
                                                        updateCallback: () =>
                                                            safeSetState(() {}),
                                                        child: ButtonWidget(
                                                          icon: Icon(
                                                            Icons.help,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                            size: 24.0,
                                                          ),
                                                          iconPresent: true,
                                                          iconEndPresent: false,
                                                          content:
                                                              _model.isPaused ==
                                                                      true
                                                                  ? 'Resume'
                                                                  : 'Pause',
                                                          variant: 'secondary',
                                                          size: 'medium',
                                                          fullWidth: true,
                                                          loading: false,
                                                          disabled: false,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        await NativeBridge
                                                            .stopBroadcast();
                                                        if (mounted) {
                                                          _navigateToCompleted();
                                                        }
                                                      },
                                                      child: wrapWithModel(
                                                        model:
                                                            _model.buttonModel2,
                                                        updateCallback: () =>
                                                            safeSetState(() {}),
                                                        child: ButtonWidget(
                                                          icon: Icon(
                                                            Icons.stop_rounded,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                            size: 24.0,
                                                          ),
                                                          iconPresent: true,
                                                          iconEndPresent: false,
                                                          content: 'Stop',
                                                          variant:
                                                              'destructive',
                                                          size: 'medium',
                                                          fullWidth: true,
                                                          loading: false,
                                                          disabled: false,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 16.0)),
                                              ),
                                            ].divide(SizedBox(height: 24.0)),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(height: 16.0)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.0,
                      height: 0.0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
