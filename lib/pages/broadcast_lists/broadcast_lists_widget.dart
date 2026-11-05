import '/backend/backend.dart';
import '/components/broadcast_card/broadcast_card_widget.dart';
import '/components/button/button_widget.dart';
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
import 'broadcast_lists_model.dart';
export 'broadcast_lists_model.dart';

class BroadcastListsWidget extends StatefulWidget {
  const BroadcastListsWidget({super.key});

  static String routeName = 'BroadcastLists';
  static String routePath = '/broadcastLists';

  @override
  State<BroadcastListsWidget> createState() => _BroadcastListsWidgetState();
}

class _BroadcastListsWidgetState extends State<BroadcastListsWidget> {
  late BroadcastListsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showCsvRequirements = false;
  bool _isImporting = false;
  Key _streamKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BroadcastListsModel());
    LocalDatabase.instance.cleanupOrphanedCampaigns();
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DateTime? _parseCampaignDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;
    try {
      return DateFormat('MMM d, yyyy').parse(trimmed);
    } catch (_) {}
    try {
      return DateFormat('MMM dd, yyyy').parse(trimmed);
    } catch (_) {}
    try {
      return DateFormat.yMMMd().parse(trimmed);
    } catch (_) {}
    return null;
  }

  String _formatCampaignDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final dt = DateTime.tryParse(trimmed);
    if (dt != null) {
      return DateFormat('MMM d, yyyy').format(dt.toLocal());
    }
    return raw;
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    try {
      await LocalDatabase.instance.cleanupOrphanedCampaigns();
      await queryCampaignsRecordOnce();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

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
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        shape: BoxShape.rectangle,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 32.0, 24.0, 16.0),
                            child: _isSearching
                                ? Container(
                                    height: 48.0,
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryBackground,
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        FlutterFlowIconButton(
                                          borderRadius: 8.0,
                                          buttonSize: 36.0,
                                          fillColor: Colors.transparent,
                                          icon: Icon(
                                            Icons.arrow_back_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 22.0,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isSearching = false;
                                              _searchController.clear();
                                              _searchQuery = '';
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            autofocus: true,
                                            style: GoogleFonts.inter(
                                              color: FlutterFlowTheme.of(context)
                                                  .primaryText,
                                              fontSize: 14.5,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Search campaigns...',
                                              hintStyle: GoogleFonts.inter(
                                                color: FlutterFlowTheme.of(
                                                        context)
                                                    .secondaryText,
                                                fontSize: 14.0,
                                              ),
                                              border: InputBorder.none,
                                              isDense: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                _searchQuery = val.trim();
                                              });
                                            },
                                          ),
                                        ),
                                        if (_searchQuery.isNotEmpty)
                                          FlutterFlowIconButton(
                                            borderRadius: 8.0,
                                            buttonSize: 36.0,
                                            fillColor: Colors.transparent,
                                            icon: Icon(
                                              Icons.clear_rounded,
                                              color: FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText,
                                              size: 20.0,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Broadcast Lists',
                                            style: FlutterFlowTheme.of(context)
                                                .headlineSmall
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w800,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w800,
                                                  lineHeight: 1.3,
                                                ),
                                          ),
                                          Text(
                                            'Import and manage your broadcast campaigns.',
                                            style: FlutterFlowTheme.of(context)
                                                .bodySmall
                                                .override(
                                                  font: GoogleFonts.inter(
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
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                        ].divide(SizedBox(height: 4.0)),
                                      ),
                                      FlutterFlowIconButton(
                                        borderRadius: 8.0,
                                        buttonSize: 40.0,
                                        fillColor: Colors.transparent,
                                        icon: Icon(
                                          Icons.search_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isSearching = true;
                                          });
                                        },
                                      ),
                                    ],
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
                        child: RefreshIndicator(
                          color: FlutterFlowTheme.of(context).primary,
                          backgroundColor:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          strokeWidth: 2.5,
                          onRefresh: _handleRefresh,
                          child: SingleChildScrollView(
                            primary: false,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: StreamBuilder<List<CampaignsRecord>>(
                                    key: _streamKey,
                                    stream: queryCampaignsRecord(),
                                    builder: (context, snapshot) {
                                    // Customize what your widget looks like when it's loading.
                                    if (snapshot.connectionState ==
                                            ConnectionState.waiting &&
                                        !snapshot.hasData) {
                                      return Center(
                                        child: SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    List<CampaignsRecord>
                                        columnPaddingCampaignsRecordList =
                                        snapshot.data ?? [];

                                    return Container(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .info10,
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                              shape: BoxShape.rectangle,
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .info30,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16.0, vertical: 12.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(8.0),
                                                    onTap: () {
                                                      setState(() {
                                                        _showCsvRequirements =
                                                            !_showCsvRequirements;
                                                      });
                                                    },
                                                    child: Row(
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
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .info_outline_rounded,
                                                              color:
                                                                  FlutterFlowTheme
                                                                          .of(context)
                                                                      .onInfo,
                                                              size: 20.0,
                                                            ),
                                                            const SizedBox(
                                                                width: 8.0),
                                                            Text(
                                                              'CSV Requirements',
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .titleSmall
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .plusJakartaSans(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                    color: FlutterFlowTheme
                                                                            .of(context)
                                                                        .onPrimaryContainer,
                                                                    lineHeight:
                                                                        1.4,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        Icon(
                                                          _showCsvRequirements
                                                              ? Icons
                                                                  .keyboard_arrow_up_rounded
                                                              : Icons
                                                                  .keyboard_arrow_down_rounded,
                                                          color:
                                                              FlutterFlowTheme
                                                                      .of(context)
                                                                  .onInfo,
                                                          size: 22.0,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (_showCsvRequirements) ...[
                                                    const SizedBox(height: 12.0),
                                                    Text(
                                                      'Ensure your CSV includes \'Name\' and \'Phone\' columns for successful import.',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodySmall
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .onPrimaryContainer,
                                                            lineHeight: 1.4,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 8.0),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional
                                                              .fromSTEB(
                                                              4.0, 0.0, 4.0, 0.0),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              FlutterFlowTheme
                                                                      .of(context)
                                                                  .surface50,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12.0),
                                                          shape:
                                                              BoxShape.rectangle,
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize.min,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                'Name | Phone',
                                                                style: FlutterFlowTheme
                                                                        .of(context)
                                                                    .labelSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                      ),
                                                                      color: FlutterFlowTheme
                                                                              .of(context)
                                                                          .primaryText,
                                                                      lineHeight:
                                                                          1.2,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4.0),
                                                              Text(
                                                                'John Doe | 919876543210',
                                                                style: FlutterFlowTheme
                                                                        .of(context)
                                                                    .labelSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(),
                                                                      color: FlutterFlowTheme
                                                                              .of(context)
                                                                          .secondaryText,
                                                                      lineHeight:
                                                                          1.2,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4.0),
                                                              Text(
                                                                'Rahul | 919812345678',
                                                                style: FlutterFlowTheme
                                                                        .of(context)
                                                                    .labelSmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(),
                                                                      color: FlutterFlowTheme
                                                                              .of(context)
                                                                          .secondaryText,
                                                                      lineHeight:
                                                                          1.2,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
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
                                                    if (_isImporting) return;
                                                    Map<String, dynamic> picked;
                                                    try {
                                                      picked =
                                                          await NativeBridge
                                                              .pickCsv();
                                                    } on PlatformException
                                                        catch (e) {
                                                      if (e.code !=
                                                          'cancelled') {
                                                        if (mounted) {
                                                          showSnackbar(
                                                            context,
                                                            'Unable to read CSV: ${e.message}',
                                                          );
                                                        }
                                                      }
                                                      return;
                                                    }

                                                    final fileName = picked[
                                                                'name']
                                                            ?.toString() ??
                                                        '';
                                                    if (!fileName.toLowerCase().endsWith('.csv')) {
                                                      if (mounted) {
                                                        showSnackbar(
                                                          context,
                                                          'Only .csv files are allowed',
                                                        );
                                                      }
                                                      return;
                                                    }

                                                    final csvText = picked[
                                                            'content']
                                                        ?.toString() ??
                                                        '';
                                                    final rows =
                                                        parseCsv(csvText);
                                                    final contacts =
                                                        csvRowsToContacts(
                                                            rows);
                                                    if (contacts.isEmpty) {
                                                      if (mounted) {
                                                        showSnackbar(
                                                          context,
                                                          'No contacts found. Ensure your CSV has \'Name\' and \'Phone\' columns.',
                                                        );
                                                      }
                                                      return;
                                                    }

                                                    setState(() {
                                                      _isImporting = true;
                                                    });

                                                    try {
                                                      final campaignName =
                                                          fileName.isEmpty
                                                              ? 'CSV Import'
                                                              : fileName;
                                                      final campaignInsert =
                                                          await supabase
                                                              .from(CampaignsRecord
                                                                  .tableName)
                                                              .insert(
                                                                  createCampaignsRecordData(
                                                                deviceId:
                                                                    FFAppState()
                                                                        .userDeviceUuid,
                                                                name:
                                                                    campaignName,
                                                                contactCount:
                                                                    contacts
                                                                        .length,
                                                                createdAt:
                                                                    DateTime.now()
                                                                        .toIso8601String(),
                                                                status: 'Ready',
                                                                messageBody: '',
                                                                delaySeconds: 6,
                                                                randomizeDelay:
                                                                    true,
                                                                skipInvalid: true,
                                                                autoRetry: false,
                                                                currentIndex: 0,
                                                              ))
                                                              .select()
                                                              .single();
                                                      final campaignId = campaignInsert[
                                                          'id'];

                                                      await supabase
                                                          .from(ContactsRecord
                                                              .tableName)
                                                          .insert(contacts
                                                              .map((contact) =>
                                                                  createContactsRecordData(
                                                                    campaignId:
                                                                        campaignId,
                                                                    name: contact[
                                                                        'name'],
                                                                    phone: contact[
                                                                        'phone'],
                                                                    status:
                                                                        'Pending',
                                                                  ))
                                                              .toList());

                                                      await _handleRefresh();

                                                      if (mounted) {
                                                        showSnackbar(
                                                          context,
                                                          'Imported ${contacts.length} contacts',
                                                        );
                                                      }
                                                    } catch (e) {
                                                      if (mounted) {
                                                        showSnackbar(
                                                          context,
                                                          'Failed to import CSV: $e',
                                                        );
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        setState(() {
                                                          _isImporting = false;
                                                        });
                                                      }
                                                    }
                                                  },
                                                  child: wrapWithModel(
                                                    model: _model.buttonModel1,
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child: ButtonWidget(
                                                      icon: Icon(
                                                        Icons
                                                            .upload_file_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 24.0,
                                                      ),
                                                      iconPresent: true,
                                                      iconEndPresent: false,
                                                      content: _isImporting
                                                          ? 'Importing...'
                                                          : 'Import CSV',
                                                      variant: 'primary',
                                                      size: 'medium',
                                                      fullWidth: false,
                                                      loading: _isImporting,
                                                      disabled: _isImporting,
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
                                                    await context.pushNamed(
                                                        CreateBroadcastWidget
                                                            .routeName);
                                                    await _handleRefresh();
                                                  },
                                                  child: wrapWithModel(
                                                    model: _model.buttonModel2,
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child: ButtonWidget(
                                                      icon: Icon(
                                                        Icons.add_rounded,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryText,
                                                        size: 24.0,
                                                      ),
                                                      iconPresent: true,
                                                      iconEndPresent: false,
                                                      content:
                                                          'Create Manually',
                                                      variant: 'outline',
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
                                                    'Recent Lists',
                                                    style: FlutterFlowTheme.of(
                                                            context)
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
                                                  wrapWithModel(
                                                    model: _model.buttonModel3,
                                                    updateCallback: () =>
                                                        safeSetState(() {}),
                                                    child: ButtonWidget(
                                                      iconPresent: false,
                                                      iconEndPresent: false,
                                                      content: 'View All',
                                                      variant: 'ghost',
                                                      size: 'small',
                                                      fullWidth: false,
                                                      loading: false,
                                                      disabled: false,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Builder(
                                                  builder: (context) {
                                                    final listWithIndex = columnPaddingCampaignsRecordList.asMap().entries.toList();
                                                    listWithIndex.sort((entryA, entryB) {
                                                      final a = entryA.value;
                                                      final b = entryB.value;
                                                      final dateA = _parseCampaignDate(a.createdAt);
                                                      final dateB = _parseCampaignDate(b.createdAt);
                                                      if (dateA != null && dateB != null) {
                                                        final cmp = dateB.compareTo(dateA);
                                                        if (cmp != 0) return cmp;
                                                      } else if (dateA != null) {
                                                        return -1;
                                                      } else if (dateB != null) {
                                                        return 1;
                                                      }
                                                      return entryB.key.compareTo(entryA.key);
                                                    });
                                                    final sortedCampaigns = listWithIndex.map((e) => e.value).toList();
                                                    final displayCampaigns = functions.filteredCampaigns(sortedCampaigns, _searchQuery);

                                                    if (displayCampaigns.isEmpty) {
                                                      return Padding(
                                                        padding: const EdgeInsets.all(32.0),
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              _searchQuery.isNotEmpty
                                                                  ? Icons.search_off_rounded
                                                                  : Icons.inventory_2_rounded,
                                                              color: FlutterFlowTheme.of(context).secondaryText,
                                                              size: 48.0,
                                                            ),
                                                            const SizedBox(height: 12.0),
                                                            Text(
                                                              _searchQuery.isNotEmpty
                                                                  ? 'No campaigns found'
                                                                  : 'No broadcast lists yet',
                                                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                                                font: GoogleFonts.plusJakartaSans(
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                                color: FlutterFlowTheme.of(context).primaryText,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4.0),
                                                            Text(
                                                              _searchQuery.isNotEmpty
                                                                  ? 'Try searching with a different keyword'
                                                                  : 'Import a CSV to start your first campaign',
                                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                font: GoogleFonts.inter(),
                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }

                                                    return ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      primary: false,
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      scrollDirection: Axis.vertical,
                                                      itemCount: displayCampaigns.length,
                                                      itemBuilder: (context, itemIndex) {
                                                        final itemItem = displayCampaigns[itemIndex];
                                                        return Dismissible(
                                                          key: Key('dismiss_${itemItem.id}'),
                                                          direction: DismissDirection.endToStart,
                                                          background: Container(
                                                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                                                            alignment: Alignment.centerRight,
                                                            padding: const EdgeInsets.only(right: 20.0),
                                                            decoration: BoxDecoration(
                                                              color: FlutterFlowTheme.of(context).error,
                                                              borderRadius: BorderRadius.circular(20.0),
                                                            ),
                                                            child: const Icon(
                                                              Icons.delete_outline_rounded,
                                                              color: Colors.white,
                                                              size: 26.0,
                                                            ),
                                                          ),
                                                          confirmDismiss: (direction) async {
                                                            return await showDialog<bool>(
                                                              context: context,
                                                              builder: (ctx) => AlertDialog(
                                                                title: const Text('Delete Campaign'),
                                                                content: Text(
                                                                    'Are you sure you want to delete "${itemItem.name}"?'),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(ctx).pop(false),
                                                                    child: const Text('Cancel'),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(ctx).pop(true),
                                                                    style: TextButton.styleFrom(
                                                                      foregroundColor:
                                                                          FlutterFlowTheme.of(context).error,
                                                                    ),
                                                                    child: const Text('Delete'),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          },
                                                          onDismissed: (direction) async {
                                                            await localDb.delete(
                                                              CampaignsRecord.tableName,
                                                              where: 'id = ?',
                                                              whereArgs: [itemItem.id],
                                                            );
                                                            showSnackbar(context, 'Campaign deleted');
                                                            await _handleRefresh();
                                                          },
                                                          child: InkWell(
                                                            splashColor: Colors.transparent,
                                                            focusColor: Colors.transparent,
                                                            hoverColor: Colors.transparent,
                                                            highlightColor: Colors.transparent,
                                                            onTap: () async {
                                                              await context.pushNamed(
                                                                BroadcastDetailsWidget.routeName,
                                                                queryParameters: {
                                                                  'campaignId': serializeParam(
                                                                    itemItem.id,
                                                                    ParamType.String,
                                                                  ),
                                                                }.withoutNulls,
                                                              );
                                                              await _handleRefresh();
                                                            },
                                                            child: BroadcastCardWidget(
                                                              key: Key('Key189_${itemIndex}_of_${displayCampaigns.length}'),
                                                              tapAction: 'navigate("broadcast_details", {campaign_id: "${itemItem.id}"})',
                                                              name: itemItem.name,
                                                              count: itemItem.contactCount.toString(),
                                                              date: _formatCampaignDate(itemItem.createdAt),
                                                              status: itemItem.status,
                                                              statusColor: itemItem.status == 'Ready'
                                                                  ? FlutterFlowTheme.of(context).success
                                                                  : (itemItem.status == 'Sending'
                                                                      ? FlutterFlowTheme.of(context).warning
                                                                      : (itemItem.status == 'Completed'
                                                                          ? FlutterFlowTheme.of(context).info
                                                                          : FlutterFlowTheme.of(context).error)),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                            ].divide(SizedBox(height: 16.0)),
                                          ),
                                        ].divide(SizedBox(height: 24.0)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                             ],
                           ),
                         ),
                       ),
                     ),
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
