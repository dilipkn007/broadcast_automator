import '/backend/backend.dart';
import '/components/broadcast_card/broadcast_card_widget.dart';
import '/components/button/button_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'broadcast_lists_model.dart';
import '/components/permission_health_card/permission_health_card_widget.dart';
import '/components/permission_wizard/permission_wizard_dialog.dart';
import '/services/native_bridge.dart';
export 'broadcast_lists_model.dart';

class BroadcastListsWidget extends StatefulWidget {
  const BroadcastListsWidget({super.key});

  static String routeName = 'BroadcastLists';
  static String routePath = '/broadcastLists';

  @override
  State<BroadcastListsWidget> createState() => _BroadcastListsWidgetState();
}

class _BroadcastListsWidgetState extends State<BroadcastListsWidget>
    with WidgetsBindingObserver {
  late BroadcastListsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showAllLists = false;
  Key _streamKey = UniqueKey();

  bool _isAccessibilityEnabled = false;
  bool _canDrawOverlays = false;
  bool _hasCheckedPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = createModel(context, () => BroadcastListsModel());
    LocalDatabase.instance.cleanupOrphanedCampaigns();
    _checkPermissions();
    _checkFirstLaunchWizard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final accessibility = await NativeBridge.isAccessibilityEnabled();
      final overlay = await NativeBridge.canDrawOverlays();
      if (!mounted) return;
      setState(() {
        _isAccessibilityEnabled = accessibility;
        _canDrawOverlays = overlay;
        _hasCheckedPermissions = true;
      });
    } catch (_) {}
  }

  Future<void> _checkFirstLaunchWizard() async {
    try {
      final hasSeen = await PermissionWizardDialog.hasSeenWizard();
      if (!hasSeen) {
        final accessibility = await NativeBridge.isAccessibilityEnabled();
        final overlay = await NativeBridge.canDrawOverlays();
        if (!accessibility || !overlay) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            PermissionWizardDialog.show(
              context,
              onPermissionsChanged: _checkPermissions,
            );
          });
        }
      }
    } catch (_) {}
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
      await _checkPermissions();
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
                                          if (_hasCheckedPermissions)
                                            PermissionHealthCardWidget(
                                              isAccessibilityEnabled:
                                                  _isAccessibilityEnabled,
                                              canDrawOverlays: _canDrawOverlays,
                                              onEnableAccessibility: () async {
                                                await NativeBridge
                                                    .openAccessibilitySettings();
                                              },
                                              onAllowOverlay: () async {
                                                await NativeBridge
                                                    .openOverlaySettings();
                                              },
                                              onOpenGuide: () {
                                                PermissionWizardDialog.show(
                                                  context,
                                                  onPermissionsChanged:
                                                      _checkPermissions,
                                                );
                                              },
                                            ),
                                          InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
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
                                                  color: Colors.white,
                                                  size: 24.0,
                                                ),
                                                iconPresent: true,
                                                iconEndPresent: false,
                                                content: 'Create',
                                                variant: 'primary',
                                                size: 'large',
                                                fullWidth: true,
                                                loading: false,
                                                disabled: false,
                                              ),
                                            ),
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
                                              final bool hasMoreThanEight = displayCampaigns.length > 8;
                                              final bool isSearching = _searchQuery.trim().isNotEmpty;
                                              final campaignsToShow = (_showAllLists || isSearching || !hasMoreThanEight)
                                                  ? displayCampaigns
                                                  : displayCampaigns.take(8).toList();

                                              return Column(
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
                                                      if (hasMoreThanEight && !isSearching)
                                                        InkWell(
                                                          splashColor: Colors.transparent,
                                                          focusColor: Colors.transparent,
                                                          hoverColor: Colors.transparent,
                                                          highlightColor: Colors.transparent,
                                                          onTap: () {
                                                            setState(() {
                                                              _showAllLists = !_showAllLists;
                                                            });
                                                          },
                                                          child: wrapWithModel(
                                                            model: _model.buttonModel3,
                                                            updateCallback: () =>
                                                                safeSetState(() {}),
                                                            child: ButtonWidget(
                                                              iconPresent: false,
                                                              iconEndPresent: false,
                                                              content: _showAllLists ? 'Show Less' : 'View All',
                                                              variant: 'ghost',
                                                              size: 'small',
                                                              fullWidth: false,
                                                              loading: false,
                                                              disabled: false,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                    if (displayCampaigns.isEmpty)
                                                      Padding(
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
                                                                  : 'Create a campaign to get started',
                                                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                                                font: GoogleFonts.inter(),
                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    else
                                                      ListView.builder(
                                                      padding: EdgeInsets.zero,
                                                      primary: false,
                                                      shrinkWrap: true,
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      scrollDirection: Axis.vertical,
                                                      itemCount: campaignsToShow.length,
                                                      itemBuilder: (context, itemIndex) {
                                                        final itemItem = campaignsToShow[itemIndex];
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
                                                              key: Key('Key189_${itemIndex}_of_${campaignsToShow.length}'),
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
                                                    ),
                                                ].divide(SizedBox(height: 16.0)),
                                              );
                                            },
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
