import '/backend/backend.dart';
import '/components/create_campaign_from_history_sheet.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateBroadcastWidget extends StatefulWidget {
  const CreateBroadcastWidget({
    super.key,
    this.sourceCampaignId,
  });

  final String? sourceCampaignId;

  static String routeName = 'CreateBroadcast';
  static String routePath = '/createBroadcast';

  @override
  State<CreateBroadcastWidget> createState() => _CreateBroadcastWidgetState();
}

class _CreateBroadcastWidgetState extends State<CreateBroadcastWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<_ContactRow> _rows = [_ContactRow()];
  bool _saving = false;
  bool _loadingSource = false;

  @override
  void initState() {
    super.initState();
    if (widget.sourceCampaignId != null &&
        widget.sourceCampaignId!.isNotEmpty) {
      _loadFromHistoricalCampaign(widget.sourceCampaignId!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFromHistoricalCampaign(String campaignId) async {
    setState(() => _loadingSource = true);
    try {
      final campaign = await CampaignsRecord.getDocumentOnce(campaignId);
      final contacts = await queryContactsRecordOnce(
        queryBuilder: (q) => q.where('campaign_id', isEqualTo: campaignId),
      );

      if (!mounted) return;

      if (contacts.isNotEmpty) {
        for (final row in _rows) {
          row.dispose();
        }
        _rows.clear();

        for (final c in contacts) {
          final row = _ContactRow();
          row.nameController.text = c.name;
          row.phoneController.text = c.phone;
          _rows.add(row);
        }

        if (_nameController.text.trim().isEmpty && campaign != null) {
          _nameController.text = '${campaign.name} (Follow-up)';
        }

        showSnackbar(context,
            'Imported ${contacts.length} contacts from "${campaign?.name ?? "campaign"}"');
      } else {
        showSnackbar(context, 'No contacts found in selected campaign');
      }
    } catch (e) {
      if (mounted) showSnackbar(context, 'Error loading contacts: $e');
    } finally {
      if (mounted) setState(() => _loadingSource = false);
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(_ContactRow());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  Future<void> _createCampaign() async {
    if (_saving) return;
    if (_nameController.text.trim().isEmpty) {
      showSnackbar(context, 'Enter a campaign name');
      return;
    }
    final contacts = <Map<String, String>>[];
    for (final row in _rows) {
      final name = row.nameController.text.trim();
      final phone = row.phoneController.text.trim();
      if (name.isEmpty && phone.isEmpty) continue;
      if (phone.isEmpty) {
        showSnackbar(context, 'Every contact needs a phone number');
        return;
      }
      contacts.add({
        'name': name,
        'phone': phone,
      });
    }
    if (contacts.isEmpty) {
      showSnackbar(context, 'Add at least one contact');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // -----------------------------------------------------------------------
      // 2. CREATING CAMPAIGNS: INJECTING SAVED DEVICE_ID
      // Includes the device_id retrieved from FFAppState().userDeviceUuid
      // in the Supabase public.campaigns insert payload.
      // -----------------------------------------------------------------------
      final campaignInsert = await localDb
          .from(CampaignsRecord.tableName)
          .insert(createCampaignsRecordData(
            deviceId: FFAppState().userDeviceUuid,
            name: _nameController.text.trim(),
            contactCount: contacts.length,
            createdAt: DateTime.now().toIso8601String(),
            status: 'Ready',
            messageBody: '',
            delaySeconds: 6,
            randomizeDelay: true,
            skipInvalid: true,
            autoRetry: false,
            currentIndex: 0,
          ))
          .select()
          .single();
      final campaignId = campaignInsert['id'].toString();

      await localDb.from(ContactsRecord.tableName).insert(
        contacts
            .map((contact) => createContactsRecordData(
                  campaignId: campaignId,
                  name: contact['name'],
                  phone: contact['phone'],
                  status: 'Pending',
                ))
            .toList(),
      );

      if (!mounted) return;
      context.goNamed(
        BroadcastDetailsWidget.routeName,
        queryParameters: {
          'campaignId': campaignId,
        }.withoutNulls,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      showSnackbar(context, 'Could not create campaign: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Text(
            'Create Broadcast List',
            style: FlutterFlowTheme.of(context).headlineMedium,
          ),
          centerTitle: false,
        ),
      body: SafeArea(
        top: true,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 32.0),
            children: [
              Text(
                'Campaign Name',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 24.0),
                child: TextFormField(
                  controller: _nameController,
                  style: FlutterFlowTheme.of(context).bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'e.g. Summer Sale',
                    labelStyle: FlutterFlowTheme.of(context).bodySmall,
                    hintStyle: FlutterFlowTheme.of(context).bodySmall,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Contacts',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          '${_rows.length}',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                color: FlutterFlowTheme.of(context).primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showSelectHistoricalCampaignSheet(
                        context,
                        onCampaignSelected: (c) =>
                            _loadFromHistoricalCampaign(c.id),
                      );
                    },
                    icon: Icon(
                      Icons.history_rounded,
                      size: 16.0,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                    label: Text(
                      'Import from Past Campaign',
                      style: GoogleFonts.inter(
                        color: FlutterFlowTheme.of(context).primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_loadingSource)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: LinearProgressIndicator(
                    color: FlutterFlowTheme.of(context).primary,
                    backgroundColor: FlutterFlowTheme.of(context).alternate,
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 16.0),
                child: Text(
                  'Enter each contact\'s name and phone number',
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
              ),
              for (var i = 0; i < _rows.length; i++)
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _rows[i].nameController,
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          decoration: _contactDecoration('Name'),
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _rows[i].phoneController,
                          style: FlutterFlowTheme.of(context).bodyMedium,
                          decoration: _contactDecoration('Phone number'),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      if (_rows.length > 1)
                        IconButton(
                          onPressed: () => _removeRow(i),
                          icon: Icon(
                            Icons.remove_circle_outline_rounded,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 22.0,
                          ),
                        )
                      else
                        SizedBox(width: 48.0),
                    ],
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _addRow,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 20.0,
                  ),
                  label: Text(
                    'Add Contact',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _createCampaign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      foregroundColor: FlutterFlowTheme.of(context).primaryText,
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _saving
                        ? SizedBox(
                            width: 22.0,
                            height: 22.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: FlutterFlowTheme.of(context).primaryText,
                            ),
                          )
                        : Text(
                            'Create Campaign',
                            style: FlutterFlowTheme.of(context).titleMedium,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  InputDecoration _contactDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: FlutterFlowTheme.of(context).bodySmall,
      hintStyle: FlutterFlowTheme.of(context).bodySmall,
      contentPadding: EdgeInsetsDirectional.fromSTEB(12.0, 14.0, 12.0, 14.0),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
    );
  }
}

class _ContactRow {
  _ContactRow();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}
