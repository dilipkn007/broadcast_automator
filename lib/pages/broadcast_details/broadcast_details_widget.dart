import '/backend/backend.dart';
import '/components/button/button_widget.dart';
import '/components/slider/slider_widget.dart';
import '/components/switch_component/switch_component_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/services/native_bridge.dart';
import 'broadcast_details_model.dart';
export 'broadcast_details_model.dart';

class BroadcastDetailsWidget extends StatefulWidget {
  const BroadcastDetailsWidget({
    super.key,
    this.campaignId,
  });

  final String? campaignId;

  static String routeName = 'BroadcastDetails';
  static String routePath = '/broadcastDetails';

  @override
  State<BroadcastDetailsWidget> createState() => _BroadcastDetailsWidgetState();
}

class _BroadcastDetailsWidgetState extends State<BroadcastDetailsWidget> {
  late BroadcastDetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, String>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BroadcastDetailsModel());
    
    // Initialize the text controller and add a listener to keep messageBody synchronized
    _model.textFieldModel.inputTextController = TextEditingController();
    _model.textFieldModel.inputTextController!.addListener(() {
      _model.messageBody = _model.textFieldModel.inputTextController!.text;
      safeSetState(() {});
    });

    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    final campaignId = widget.campaignId;
    if (campaignId == null || campaignId.isEmpty) return;
    final list = await queryAttachmentsRecordOnce(
      queryBuilder: (q) => q.where('campaign_id', isEqualTo: campaignId),
    );
    if (!mounted) return;
    setState(() {
      _attachments = list.map((a) {
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

  Future<void> _pickAndAddAttachment() async {
    Map<String, dynamic> picked;
    try {
      picked = await NativeBridge.pickAttachment();
    } on PlatformException catch (e) {
      if (e.code != 'cancelled') {
        showSnackbar(context, 'Unable to pick attachment: ${e.message}');
      }
      return;
    }
    final campaignId = widget.campaignId;
    if (campaignId == null || campaignId.isEmpty) return;
    final response = await supabase.from(AttachmentsRecord.tableName).insert(
          createAttachmentsRecordData(
            campaignId: campaignId,
            sourceUrl: picked['path']?.toString(),
            type: picked['mimeType']?.toString(),
          ),
        ).select();
    final String insertedId = (response.isNotEmpty ? response.first['id'] : '').toString();

    if (!mounted) return;
    setState(() {
      _attachments = [
        ..._attachments,
        {
          'id': insertedId,
          'path': picked['path']?.toString() ?? '',
          'mimeType': picked['mimeType']?.toString() ?? '',
          'name': picked['name']?.toString() ?? 'Attachment',
        },
      ];
    });
    showSnackbar(context, 'Attachment added');
  }

  Future<void> _deleteAttachment(Map<String, String> attachment) async {
    final id = attachment['id'];
    if (id == null || id.isEmpty) return;
    try {
      await supabase.from(AttachmentsRecord.tableName).delete().eq('id', id);
      if (!mounted) return;
      setState(() {
        _attachments.removeWhere((item) => item['id'] == id);
      });
      showSnackbar(context, 'Attachment removed');
    } catch (e) {
      showSnackbar(context, 'Unable to remove attachment: $e');
    }
  }

  Widget _buildAttachmentThumb(BuildContext context, Map<String, String> attachment) {
    final name = attachment['name'] ?? 'Attachment';
    return SizedBox(
      width: 100.0,
      height: 100.0,
      child: Stack(
        children: [
          Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12.0),
              shape: BoxShape.rectangle,
              border: Border.all(
                color: FlutterFlowTheme.of(context).primary,
                width: 1.5,
              ),
            ),
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 24.0,
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).labelSmall.copyWith(
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 4.0,
            right: 4.0,
            child: FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 20.0,
              borderWidth: 1.0,
              buttonSize: 24.0,
              fillColor: FlutterFlowTheme.of(context).alternate,
              icon: Icon(
                Icons.close_rounded,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 14.0,
              ),
              onPressed: () async {
                await _deleteAttachment(attachment);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaignId = widget!.campaignId ?? '';
    return StreamBuilder<CampaignsRecord>(
      stream: CampaignsRecord.getDocument(campaignId),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                  if (campaignId.isEmpty)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          24.0, 24.0, 24.0, 0.0),
                      child: Text(
                        'No campaign selected. Go back and choose a campaign.',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        final broadcastDetailsCampaignsRecord = snapshot.data!;

        if (_model.messageBody == null) {
          _model.messageBody = broadcastDetailsCampaignsRecord.messageBody;
          _model.textFieldModel.inputTextController!.text = _model.messageBody ?? '';
        }

        if (_model.delaySeconds == null) {
          _model.delaySeconds = broadcastDetailsCampaignsRecord.delaySeconds;
        }

        if (_model.randomizeDelay == null) {
          _model.randomizeDelay = broadcastDetailsCampaignsRecord.randomizeDelay;
        }

        if (_model.autoPauseEnabled == null) {
          _model.autoPauseEnabled = FFAppState().prefs.getBool('campaign_auto_pause_enabled_${broadcastDetailsCampaignsRecord.id}') ?? false;
        }

        if (_model.autoPauseMinutes == null) {
          _model.autoPauseMinutes = FFAppState().prefs.getInt('campaign_auto_pause_minutes_${broadcastDetailsCampaignsRecord.id}') ?? 10;
        }

        if (_model.autoPauseMinutesTextController == null) {
          _model.autoPauseMinutesTextController = TextEditingController(
            text: (_model.autoPauseMinutes ?? 10).toString(),
          );
        }
        if (_model.autoPauseMinutesFocusNode == null) {
          _model.autoPauseMinutesFocusNode = FocusNode();
        }

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
                    child: Container(
                      child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            shape: BoxShape.rectangle,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    24.0, 32.0, 24.0, 16.0),
                                child: Container(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          FlutterFlowIconButton(
                                            borderRadius: 8.0,
                                            buttonSize: 40.0,
                                            fillColor: Colors.transparent,
                                            icon: Icon(
                                              Icons.arrow_back_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 24.0,
                                            ),
                                            onPressed: () async {
                                              context.pop();
                                            },
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Broadcast Details',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                              ),
                                              StreamBuilder<
                                                  List<CampaignsRecord>>(
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
                                                      textCampaignsRecordList =
                                                      snapshot.data!;

                                                  return Text(
                                                    '${getJsonField(
                                                          functions.currentCampaign(
                                                              textCampaignsRecordList
                                                                  .toList(),
                                                              widget!
                                                                  .campaignId!),
                                                          r'''$.status''',
                                                        ) != null ? getJsonField(
                                                        functions.currentCampaign(
                                                            textCampaignsRecordList
                                                                .toList(),
                                                            widget!
                                                                .campaignId!),
                                                        r'''$.status''',
                                                      ).toString() : 'Draft'} · ${getJsonField(
                                                          functions.currentCampaign(
                                                              textCampaignsRecordList
                                                                  .toList(),
                                                              widget!
                                                                  .campaignId!),
                                                          r'''$.name''',
                                                        ) != null ? getJsonField(
                                                        functions.currentCampaign(
                                                            textCampaignsRecordList
                                                                .toList(),
                                                            widget!
                                                                .campaignId!),
                                                        r'''$.name''',
                                                      ).toString() : ''}',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodySmall
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodySmall
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ].divide(SizedBox(width: 16.0)),
                                      ),
                                      FlutterFlowIconButton(
                                        borderRadius: 8.0,
                                        buttonSize: 40.0,
                                        fillColor: Colors.transparent,
                                        icon: Icon(
                                          Icons.more_vert_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        onPressed: () {
                                          print('IconButton pressed ...');
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: 1.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  shape: BoxShape.rectangle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            child: SingleChildScrollView(
                              primary: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Container(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Message Content',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .labelLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelLarge
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelLarge
                                                              .fontStyle,
                                                      lineHeight: 1.3,
                                                    ),
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .surfaceVariant,
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
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        wrapWithModel(
                                                          model: _model
                                                              .textFieldModel,
                                                          updateCallback: () =>
                                                              safeSetState(
                                                                  () {}),
                                                          child:
                                                              TextFieldWidget(
                                                            label: '',
                                                            labelPresent: false,
                                                            helper: '',
                                                            helperPresent:
                                                                false,
                                                            leadingIconPresent:
                                                                false,
                                                            trailingIconPresent:
                                                                false,
                                                            hint:
                                                                'Type your message here...',
                                                            value: _model
                                                                .messageBody,
                                                            onChange: '',
                                                            onSubmit: '',
                                                            variant: 'ghost',
                                                            error: false,
                                                          ),
                                                        ),
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
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              children: [
                                                                FlutterFlowIconButton(
                                                                  borderRadius:
                                                                      8.0,
                                                                  buttonSize:
                                                                      40.0,
                                                                  fillColor: Colors
                                                                      .transparent,
                                                                  icon: Icon(
                                                                    Icons
                                                                        .mood_rounded,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                    size: 20.0,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    print(
                                                                        'IconButton pressed ...');
                                                                  },
                                                                ),
                                                                FlutterFlowIconButton(
                                                                  borderRadius:
                                                                      8.0,
                                                                  buttonSize:
                                                                      40.0,
                                                                  fillColor: Colors
                                                                      .transparent,
                                                                  icon: Icon(
                                                                    Icons
                                                                        .alternate_email_rounded,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryText,
                                                                    size: 20.0,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    print(
                                                                        'IconButton pressed ...');
                                                                  },
                                                                ),
                                                              ].divide(SizedBox(
                                                                  width: 8.0)),
                                                            ),
                                                            Text(
                                                              '${valueOrDefault<String>(
                                                                _model
                                                                    .messageBody,
                                                                '',
                                                              ).length} / 160',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .labelSmall
                                                                  .override(
                                                                    font: GoogleFonts
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
                                                      ].divide(SizedBox(
                                                          height: 16.0)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ].divide(SizedBox(height: 16.0)),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Media & Attachments',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelLarge
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelLarge
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelLarge
                                                                  .fontStyle,
                                                          lineHeight: 1.3,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Add +',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .onBackground,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.3,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    ..._attachments.map(
                                                      (attachment) =>
                                                          _buildAttachmentThumb(
                                                        context,
                                                        attachment,
                                                      ),
                                                    ),
                                                    if (_attachments.isNotEmpty)
                                                      const SizedBox(width: 16.0),
                                                    InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () =>
                                                          _pickAndAddAttachment(),
                                                      child: Container(
                                                        width: 100.0,
                                                        height: 100.0,
                                                        decoration: BoxDecoration(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      12.0),
                                                          shape:
                                                              BoxShape.rectangle,
                                                          border: Border.all(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .alternate,
                                                            width: 1.0,
                                                          ),
                                                        ),
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, 0.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .add_photo_alternate_rounded,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .onSurface,
                                                              size: 24.0,
                                                            ),
                                                            Text(
                                                              'Upload',
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
                                                                        .onSurface,
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
                                                              height: 4.0)),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ].divide(SizedBox(height: 16.0)),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              shape: BoxShape.rectangle,
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .alternate,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(24.0),
                                              child: Container(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Text(
                                                      'Automation Settings',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .titleSmall
                                                          .override(
                                                            font: GoogleFonts
                                                                .plusJakartaSans(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontStyle,
                                                            ),
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontStyle,
                                                            lineHeight: 1.4,
                                                          ),
                                                    ),
                                                    Divider(
                                                      height: 16.0,
                                                      thickness: 1.0,
                                                      indent: 0.0,
                                                      endIndent: 0.0,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate,
                                                    ),
                                                    wrapWithModel(
                                                      model: _model.sliderModel,
                                                      updateCallback: () =>
                                                          safeSetState(() {}),
                                                      child: SliderWidget(
                                                        label: 'Message Delay',
                                                        labelPresent: true,
                                                        description:
                                                            'Average time between sends',
                                                        descriptionPresent:
                                                            true,
                                                        valueLabel:
                                                            '${_model.delaySeconds?.toString() ?? "6"} seconds',
                                                        valueLabelPresent: true,
                                                        step: 1.0,
                                                        divisions: 24,
                                                        valuePercentage: (_model.delaySeconds ?? 6).toDouble(),
                                                        min: 6.0,
                                                        max: 30.0,
                                                        onChanged: (val) {
                                                          _model.delaySeconds = val.round();
                                                        },
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        variant: 'Material',
                                                        disabled: false,
                                                        showTicks: true,
                                                      ),
                                                    ),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        wrapWithModel(
                                                            model: _model
                                                                .switchModel1,
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                SwitchComponentWidget(
                                                              label:
                                                                  'Randomize delay (± 3s)',
                                                              labelPresent: true,
                                                              variant: 'Android',
                                                              active: _model.randomizeDelay ?? true,
                                                              onChanged: (val) {
                                                                _model.randomizeDelay = val;
                                                                safeSetState(() {});
                                                              },
                                                            ),
                                                          ),
                                                          wrapWithModel(
                                                            model: _model
                                                                .switchModel2,
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                SwitchComponentWidget(
                                                              label:
                                                                  'Auto-retry failed sends',
                                                              labelPresent: true,
                                                              variant: 'Android',
                                                              active: _model.autoRetry ?? false,
                                                              onChanged: (val) {
                                                                _model.autoRetry = val;
                                                                safeSetState(() {});
                                                              },
                                                            ),
                                                          ),
                                                          wrapWithModel(
                                                            model: _model
                                                                .switchModelAutoPause,
                                                            updateCallback: () =>
                                                                safeSetState(
                                                                    () {}),
                                                            child:
                                                                SwitchComponentWidget(
                                                              label:
                                                                  'Auto-pause campaign',
                                                              labelPresent: true,
                                                              variant: 'Android',
                                                              active: _model.autoPauseEnabled ?? false,
                                                              onChanged: (val) {
                                                                _model.autoPauseEnabled = val;
                                                                FFAppState().prefs.setBool('campaign_auto_pause_enabled_${broadcastDetailsCampaignsRecord.id}', val);
                                                                safeSetState(() {});
                                                              },
                                                            ),
                                                          ),
                                                          if (_model.autoPauseEnabled ?? false)
                                                            Padding(
                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 4.0),
                                                              child: Container(
                                                                width: double.infinity,
                                                                padding: EdgeInsetsDirectional.fromSTEB(14.0, 12.0, 14.0, 12.0),
                                                                decoration: BoxDecoration(
                                                                  color: FlutterFlowTheme.of(context).primaryBackground,
                                                                  borderRadius: BorderRadius.circular(10.0),
                                                                  border: Border.all(
                                                                    color: FlutterFlowTheme.of(context).alternate,
                                                                    width: 1.0,
                                                                  ),
                                                                ),
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Row(
                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                      children: [
                                                                        Text(
                                                                          'Pause duration',
                                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                            font: GoogleFonts.plusJakartaSans(
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                            color: FlutterFlowTheme.of(context).primaryText,
                                                                          ),
                                                                        ),
                                                                        Row(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            Container(
                                                                              width: 70.0,
                                                                              height: 38.0,
                                                                              child: TextFormField(
                                                                                controller: _model.autoPauseMinutesTextController,
                                                                                focusNode: _model.autoPauseMinutesFocusNode,
                                                                                keyboardType: TextInputType.number,
                                                                                textAlign: TextAlign.center,
                                                                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  font: GoogleFonts.plusJakartaSans(
                                                                                    fontWeight: FontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                                decoration: InputDecoration(
                                                                                  isDense: true,
                                                                                  contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                                                                  filled: true,
                                                                                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                  enabledBorder: OutlineInputBorder(
                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                    borderSide: BorderSide(
                                                                                      color: FlutterFlowTheme.of(context).alternate,
                                                                                      width: 1.0,
                                                                                    ),
                                                                                  ),
                                                                                  focusedBorder: OutlineInputBorder(
                                                                                    borderRadius: BorderRadius.circular(8.0),
                                                                                    borderSide: BorderSide(
                                                                                      color: FlutterFlowTheme.of(context).primary,
                                                                                      width: 2.0,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                onChanged: (val) {
                                                                                  final minutes = int.tryParse(val) ?? 0;
                                                                                  _model.autoPauseMinutes = minutes;
                                                                                  FFAppState().prefs.setInt(
                                                                                    'campaign_auto_pause_minutes_${broadcastDetailsCampaignsRecord.id}',
                                                                                    minutes,
                                                                                  );
                                                                                },
                                                                              ),
                                                                            ),
                                                                            SizedBox(width: 8.0),
                                                                            Text(
                                                                              'minutes',
                                                                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                font: GoogleFonts.plusJakartaSans(
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                  fontWeight: FontWeight.w500,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Padding(
                                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 0.0),
                                                                      child: Text(
                                                                        'Automatically pauses sending after running continuously for this time to prevent WhatsApp account rate limits.',
                                                                        style: FlutterFlowTheme.of(context).labelSmall.override(
                                                                          font: GoogleFonts.plusJakartaSans(
                                                                            color: FlutterFlowTheme.of(context).secondaryText,
                                                                            fontSize: 11.0,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                        ].divide(SizedBox(
                                                            height: 8.0)),
                                                      ),
                                                  ].divide(
                                                      SizedBox(height: 16.0)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          StreamBuilder<List<ContactsRecord>>(
                                            stream: queryContactsRecord(
                                              queryBuilder: (q) => q.where(
                                                  'campaign_id',
                                                  isEqualTo: widget.campaignId),
                                            ),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 30.0,
                                                    height: 30.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                    ),
                                                  ),
                                                );
                                              }
                                              final contacts = snapshot.data!;
                                              if (contacts.isEmpty) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .surfaceVariant,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                    shape: BoxShape.rectangle,
                                                    border: Border.all(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .alternate,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.all(24.0),
                                                    child: Center(
                                                      child: Text(
                                                        'No contacts found for this campaign.',
                                                        style: FlutterFlowTheme
                                                                .of(context)
                                                            .bodyMedium,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .surfaceVariant,
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
                                                  padding:
                                                      EdgeInsets.all(24.0),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Contacts',
                                                            style:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .override(
                                                                      font:
                                                                          GoogleFonts.plusJakartaSans(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                    ),
                                                          ),
                                                          Text(
                                                            '${contacts.length} Total',
                                                            style:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .override(
                                                                      font:
                                                                          GoogleFonts.inter(
                                                                        color:
                                                                            FlutterFlowTheme.of(context).secondaryText,
                                                                      ),
                                                                    ),
                                                          ),
                                                        ],
                                                      ),
                                                      Divider(
                                                        height: 16.0,
                                                        thickness: 1.0,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .alternate,
                                                      ),
                                                      Container(
                                                        height: 180.0,
                                                        child: Scrollbar(
                                                          child:
                                                              ListView.builder(
                                                            padding:
                                                                EdgeInsets.zero,
                                                            shrinkWrap: true,
                                                            physics:
                                                                const ClampingScrollPhysics(),
                                                            itemCount:
                                                                contacts.length,
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              final contact =
                                                                  contacts[
                                                                      index];
                                                              final isSent =
                                                                  contact.status ==
                                                                      'Sent';
                                                              final isFailed =
                                                                  contact.status ==
                                                                      'Failed';
                                                              final isPending =
                                                                  contact.status ==
                                                                          'Pending' ||
                                                                      contact.status ==
                                                                          'Sending';
                                                              final isSkipped =
                                                                  contact.status ==
                                                                      'Skipped';
                                                              final statusColor =
                                                                  isSent
                                                                      ? FlutterFlowTheme.of(context).success
                                                                      : (isFailed
                                                                          ? FlutterFlowTheme.of(context).error
                                                                          : (isPending
                                                                              ? FlutterFlowTheme.of(context).warning
                                                                              : (isSkipped ? FlutterFlowTheme.of(context).secondaryText : FlutterFlowTheme.of(context).primary)));
                                                              return Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            8.0),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          contact
                                                                              .name,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                        ),
                                                                        Text(
                                                                          contact
                                                                              .phone,
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodySmall
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                                                ),
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    Container(
                                                                      padding:
                                                                          EdgeInsets.symmetric(
                                                                              horizontal:
                                                                                  8.0,
                                                                              vertical:
                                                                                  4.0),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: statusColor
                                                                            .withOpacity(0.1),
                                                                        borderRadius:
                                                                            BorderRadius.circular(8.0),
                                                                      ),
                                                                      child: Text(
                                                                        contact.status.isNotEmpty
                                                                            ? contact
                                                                                .status
                                                                            : 'Ready',
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodySmall
                                                                            .override(
                                                                              font: GoogleFonts.inter(
                                                                                color: statusColor,
                                                                                fontWeight: FontWeight.bold,
                                                                              ),
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ].divide(SizedBox(height: 24.0)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            shape: BoxShape.rectangle,
                          ),
                          child: SafeArea(
                            top: false,
                            bottom: true,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 1.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context).alternate,
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Container(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (widget!.campaignId == null ||
                                                  widget!.campaignId == '') {
                                                return;
                                              }
  
                                              await supabase
                                                  .from(CampaignsRecord.tableName)
                                                  .update(createCampaignsRecordData(
                                                    messageBody:
                                                        _model.messageBody,
                                                    delaySeconds:
                                                        _model.delaySeconds,
                                                    randomizeDelay:
                                                        _model.randomizeDelay,
                                                    skipInvalid:
                                                        _model.skipInvalid,
                                                    autoRetry: _model.autoRetry,
                                                  ))
                                                  .eq('id',
                                                      broadcastDetailsCampaignsRecord
                                                          .id);
                                              context.pop();
                                            },
                                            child: wrapWithModel(
                                              model: _model.buttonModel1,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: ButtonWidget(
                                                iconPresent: false,
                                                iconEndPresent: false,
                                                content: 'Save Draft',
                                                variant: 'outline',
                                                size: 'large',
                                                fullWidth: false,
                                                loading: false,
                                                disabled: false,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              if (widget!.campaignId == null ||
                                                  widget!.campaignId == '') {
                                                return;
                                              }
  
                                              await supabase
                                                  .from(CampaignsRecord.tableName)
                                                  .update(createCampaignsRecordData(
                                                    messageBody:
                                                        _model.messageBody,
                                                    delaySeconds:
                                                        _model.delaySeconds,
                                                    randomizeDelay:
                                                        _model.randomizeDelay,
                                                    skipInvalid:
                                                        _model.skipInvalid,
                                                    autoRetry: _model.autoRetry,
                                                    status: 'Sending',
                                                    currentIndex: 0,
                                                  ))
                                                  .eq('id',
                                                      broadcastDetailsCampaignsRecord
                                                          .id);
  
                                              final contacts =
                                                  await queryContactsRecordOnce(
                                                queryBuilder: (q) => q.where(
                                                    'campaign_id',
                                                    isEqualTo:
                                                        widget!.campaignId),
                                              );
  
                                              await supabase
                                                  .from(ContactsRecord.tableName)
                                                  .update({'status': 'Pending'})
                                                  .eq('campaign_id',
                                                      widget!.campaignId!);
  
                                              final attachment =
                                                  _attachments.isNotEmpty
                                                      ? _attachments.first
                                                      : null;
                                                await NativeBridge.saveJob(
                                                campaignId: widget!.campaignId!,
                                                campaignName:
                                                    broadcastDetailsCampaignsRecord
                                                        .name,
                                                message:
                                                    _model.messageBody ?? '',
                                                delaySeconds:
                                                    _model.delaySeconds ?? 6,
                                                randomizeDelay:
                                                    _model.randomizeDelay ?? true,
                                                autoRetry:
                                                    _model.autoRetry ?? false,
                                                skipInvalid:
                                                    _model.skipInvalid ?? true,
                                                contacts: contacts
                                                        .map((c) => {
                                                              'id': c.id,
                                                          'name': c.name,
                                                          'phone': c.phone,
                                                        })
                                                    .toList(),
                                                attachmentPath:
                                                    attachment?['path'],
                                                attachmentMime:
                                                    attachment?['mimeType'],
                                                autoPauseMinutes: (_model.autoPauseEnabled ?? false)
                                                    ? (_model.autoPauseMinutes ?? 10)
                                                    : 0,
                                              );
  
                                              final started = await NativeBridge
                                                  .startBroadcast(
                                                widget!.campaignId!,
                                              );
  
                                              if (!(started['started'] == true)) {
                                                if (started[
                                                        'accessibilityEnabled'] ==
                                                    false) {
                                                  await NativeBridge
                                                      .openAccessibilitySettings();
                                                  showSnackbar(
                                                    context,
                                                    'Enable the "WhatsApp Broadcast Automator" accessibility service, then tap Start Broadcast again.',
                                                  );
                                                } else if (started[
                                                        'overlayPermission'] ==
                                                    false) {
                                                  await NativeBridge
                                                      .openOverlaySettings();
                                                  showSnackbar(
                                                    context,
                                                    'Allow "Display over other apps" so the progress overlay can appear on WhatsApp.',
                                                  );
                                                } else {
                                                  showSnackbar(
                                                    context,
                                                    'Could not start broadcast: ${started['error']}',
                                                  );
                                                }
                                                return;
                                              }
  
                                              if (!mounted) return;
                                              context.goNamed(
                                                SendingProgressOverlayWidget
                                                    .routeName,
                                                queryParameters: {
                                                  'campaignId': serializeParam(
                                                    widget!.campaignId,
                                                    ParamType.String,
                                                  ),
                                                }.withoutNulls,
                                              );
                                            },
                                            child: wrapWithModel(
                                              model: _model.buttonModel2,
                                              updateCallback: () =>
                                                  safeSetState(() {}),
                                              child: ButtonWidget(
                                                icon: Icon(
                                                  Icons.rocket_launch_rounded,
                                                  color:
                                                      FlutterFlowTheme.of(context)
                                                          .primaryText,
                                                  size: 24.0,
                                                ),
                                                iconPresent: true,
                                                iconEndPresent: false,
                                                content: 'Start Broadcast',
                                                variant: 'primary',
                                                size: 'large',
                                                fullWidth: false,
                                                loading: false,
                                                disabled: false,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 16.0)),
                                    ),
                                  ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
