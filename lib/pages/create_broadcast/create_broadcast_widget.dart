import '/backend/backend.dart';
import '/components/create_campaign_from_history_sheet.dart';
import '/components/phone_contacts_picker_sheet.dart';
import '/components/quick_paste_sheet.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/native_bridge.dart';

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
  final List<String> _customColumns = [];
  bool _saving = false;
  bool _loadingSource = false;
  bool _isImportingCsv = false;
  bool _showAllContacts = false;

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
        _customColumns.clear();
        if (campaign != null && campaign.customColumns.isNotEmpty) {
          _customColumns.addAll(campaign.customColumns);
        }

        for (final c in contacts) {
          final row = _ContactRow();
          row.nameController.text = c.name;
          row.phoneController.text = c.phone;
          c.extraFields.forEach((k, v) {
            if (!_customColumns.contains(k)) {
              _customColumns.add(k);
            }
            row.ensureController(k, v);
          });
          for (final col in _customColumns) {
            row.ensureController(col);
          }
          _rows.add(row);
        }

        _showAllContacts = _rows.length <= 50;

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

  Future<void> _importFromCsv() async {
    if (_isImportingCsv) return;
    Map<String, dynamic> picked;
    try {
      picked = await NativeBridge.pickCsv();
    } on PlatformException catch (e) {
      if (e.code != 'cancelled' && mounted) {
        showSnackbar(context, 'Unable to read CSV: ${e.message}');
      }
      return;
    } catch (e) {
      if (mounted) showSnackbar(context, 'Error selecting file: $e');
      return;
    }

    final fileName = picked['name']?.toString() ?? '';
    if (!fileName.toLowerCase().endsWith('.csv')) {
      if (mounted) showSnackbar(context, 'Only .csv files are allowed');
      return;
    }

    final csvText = picked['content']?.toString() ?? '';
    final rows = parseCsv(csvText);
    final parsed = parseCsvToContactsWithColumns(rows);
    final contacts = parsed.contacts;

    // Count rows with a phone number before dedup to report duplicates removed.
    final totalRowsWithPhone = rows.length > 1
        ? rows.skip(1).where((r) => r.length > 1 && r.any((cell) => cell.trim().isNotEmpty)).length
        : 0;
    final duplicatesRemoved = totalRowsWithPhone > contacts.length
        ? totalRowsWithPhone - contacts.length
        : 0;

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
      _isImportingCsv = true;
    });

    try {
      if (_nameController.text.trim().isEmpty) {
        var baseName = fileName;
        if (baseName.toLowerCase().endsWith('.csv')) {
          baseName = baseName.substring(0, baseName.length - 4);
        }
        _nameController.text = baseName;
      }

      final suffix = duplicatesRemoved > 0
          ? ' ($duplicatesRemoved duplicate${duplicatesRemoved == 1 ? '' : 's'} removed)'
          : '';
      _appendContacts(contacts, '$fileName$suffix', newColumns: parsed.customColumns);
    } finally {
      if (mounted) {
        setState(() {
          _isImportingCsv = false;
        });
      }
    }
  }

  void _appendContacts(
    List<Map<String, dynamic>> newContacts,
    String sourceDescription, {
    List<String>? newColumns,
  }) {
    if (newContacts.isEmpty) return;

    setState(() {
      if (newColumns != null) {
        for (final col in newColumns) {
          if (!_customColumns.contains(col)) {
            _customColumns.add(col);
          }
        }
      }

      final isSingleEmptyRow = _rows.length == 1 &&
          _rows[0].nameController.text.trim().isEmpty &&
          _rows[0].phoneController.text.trim().isEmpty;

      if (isSingleEmptyRow) {
        for (final row in _rows) {
          row.dispose();
        }
        _rows.clear();
      }

      for (final c in newContacts) {
        final row = _ContactRow();
        row.nameController.text = c['name']?.toString() ?? '';
        row.phoneController.text = normalizeWhatsAppNumber(c['phone']?.toString() ?? '');
        final extras = c['extra_fields'];
        if (extras is Map) {
          extras.forEach((k, v) {
            final colStr = k.toString().trim();
            if (colStr.isNotEmpty) {
              if (!_customColumns.contains(colStr)) {
                _customColumns.add(colStr);
              }
              row.ensureController(colStr, v?.toString() ?? '');
            }
          });
        }
        for (final col in _customColumns) {
          row.ensureController(col);
        }
        _rows.add(row);
      }

      _showAllContacts = _rows.length <= 50;
    });

    if (mounted) {
      showSnackbar(context, 'Added ${newContacts.length} contacts from $sourceDescription');
    }
  }

  void _openQuickPaste() {
    showQuickPasteSheet(
      context,
      onContactsPasted: (contacts) {
        _appendContacts(contacts, 'Quick Paste');
      },
    );
  }

  void _openPhoneContacts() {
    showPhoneContactsPickerSheet(
      context,
      onContactsSelected: (contacts) {
        _appendContacts(contacts, 'Phone Contacts');
      },
    );
  }

  Future<void> _showAddColumnDialog() async {
    final controller = TextEditingController();
    final colName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        title: Text(
          'Add Custom Column',
          style: FlutterFlowTheme.of(context).titleMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add dynamic fields like age, class, city, etc. You can tag them in messages as {{age}}, {{class}}.',
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: _contactDecoration('Column Name (e.g. age, class)'),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              Navigator.of(ctx).pop(val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlutterFlowTheme.of(context).primary,
              foregroundColor: FlutterFlowTheme.of(context).primaryText,
            ),
            child: const Text('Add Column'),
          ),
        ],
      ),
    );

    if (colName != null && colName.isNotEmpty) {
      final cleanCol = colName.replaceAll(RegExp(r'[{}]'), '').trim();
      if (cleanCol.isEmpty) return;
      if (cleanCol.toLowerCase() == 'name' || cleanCol.toLowerCase() == 'phone' || cleanCol.toLowerCase() == 'number') {
        showSnackbar(context, '"$cleanCol" is a built-in column');
        return;
      }
      if (_customColumns.any((c) => c.toLowerCase() == cleanCol.toLowerCase())) {
        showSnackbar(context, 'Column "$cleanCol" already exists');
        return;
      }
      setState(() {
        _customColumns.add(cleanCol);
        for (final r in _rows) {
          r.ensureController(cleanCol);
        }
      });
      showSnackbar(context, 'Added column "$cleanCol"');
    }
  }

  void _removeColumn(String colName) {
    setState(() {
      _customColumns.remove(colName);
      for (final r in _rows) {
        r.removeController(colName);
      }
    });
    showSnackbar(context, 'Removed column "$colName"');
  }

  void _clearContacts() {
    setState(() {
      for (final row in _rows) {
        row.dispose();
      }
      _rows.clear();
      final newRow = _ContactRow();
      for (final col in _customColumns) {
        newRow.ensureController(col);
      }
      _rows.add(newRow);
      _showAllContacts = false;
    });
  }

  void _addRow() {
    setState(() {
      final newRow = _ContactRow();
      for (final col in _customColumns) {
        newRow.ensureController(col);
      }
      _rows.add(newRow);
      _showAllContacts = true;
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
    final contacts = <Map<String, dynamic>>[];
    for (final row in _rows) {
      final name = row.nameController.text.trim();
      final phone = row.phoneController.text.trim();
      if (name.isEmpty && phone.isEmpty) continue;
      if (phone.isEmpty) {
        showSnackbar(context, 'Every contact needs a phone number');
        return;
      }
      final extraFields = <String, String>{};
      for (final col in _customColumns) {
        final val = row.extraControllers[col]?.text.trim() ?? '';
        if (val.isNotEmpty) {
          extraFields[col] = val;
        }
      }
      contacts.add({
        'name': name,
        'phone': phone,
        'extra_fields': extraFields,
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
            customColumns: _customColumns,
          ))
          .select()
          .single();
      final campaignId = campaignInsert['id'].toString();

      await localDb.from(ContactsRecord.tableName).insert(
        contacts
            .map((contact) => createContactsRecordData(
                  campaignId: campaignId,
                  name: contact['name'] as String?,
                  phone: contact['phone'] as String?,
                  status: 'Pending',
                  extraFields: contact['extra_fields'] as Map<String, String>?,
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
                  if (_rows.length > 1 ||
                      _rows[0].nameController.text.isNotEmpty ||
                      _rows[0].phoneController.text.isNotEmpty)
                    TextButton(
                      onPressed: _clearContacts,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.inter(
                          color: FlutterFlowTheme.of(context).error,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10.0),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openQuickPaste,
                      icon: Icon(
                        Icons.content_paste_go_rounded,
                        size: 16.0,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      label: Text(
                        'Quick Paste',
                        style: GoogleFonts.inter(
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    OutlinedButton.icon(
                      onPressed: _openPhoneContacts,
                      icon: Icon(
                        Icons.contacts_rounded,
                        size: 16.0,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      label: Text(
                        'Phone Contacts',
                        style: GoogleFonts.inter(
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    OutlinedButton.icon(
                      onPressed: _isImportingCsv ? null : _importFromCsv,
                      icon: _isImportingCsv
                          ? SizedBox(
                              width: 14.0,
                              height: 14.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: FlutterFlowTheme.of(context).primary,
                              ),
                            )
                          : Icon(
                              Icons.upload_file_rounded,
                              size: 16.0,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                      label: Text(
                        _isImportingCsv ? 'Importing CSV...' : 'Import from CSV',
                        style: GoogleFonts.inter(
                          color: FlutterFlowTheme.of(context).primary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    OutlinedButton.icon(
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
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                      ),
                    ),
                  ],
                ),
              ),
              if (_loadingSource)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: LinearProgressIndicator(
                    color: FlutterFlowTheme.of(context).primary,
                    backgroundColor: FlutterFlowTheme.of(context).alternate,
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 8.0),
                child: Text(
                  'Enter contact details manually or use an import option above',
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Columns / Variables:',
                          style: GoogleFonts.inter(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _columnChip('Name', isDefault: true),
                        _columnChip('Phone', isDefault: true),
                        for (final col in _customColumns)
                          _columnChip(
                            col,
                            isDefault: false,
                            onDeleted: () => _removeColumn(col),
                          ),
                        ActionChip(
                          avatar: Icon(
                            Icons.add_rounded,
                            size: 15.0,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                          label: Text(
                            'Add Column',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                          ),
                          backgroundColor: FlutterFlowTheme.of(context)
                              .primary
                              .withOpacity(0.08),
                          side: BorderSide(
                            color: FlutterFlowTheme.of(context)
                                .primary
                                .withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          onPressed: _showAddColumnDialog,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final displayCount = _showAllContacts
                      ? _rows.length
                      : (_rows.length > 50 ? 50 : _rows.length);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < displayCount; i++)
                        if (_customColumns.isEmpty)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 12.0),
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
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      size: 22.0,
                                    ),
                                  )
                                else
                                  SizedBox(width: 48.0),
                              ],
                            ),
                          )
                        else
                          Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: TextFormField(
                                        controller: _rows[i].nameController,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium,
                                        decoration: _contactDecoration('Name'),
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    Expanded(
                                      flex: 4,
                                      child: TextFormField(
                                        controller: _rows[i].phoneController,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium,
                                        decoration:
                                            _contactDecoration('Phone number'),
                                        keyboardType: TextInputType.phone,
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    if (_rows.length > 1)
                                      IconButton(
                                        onPressed: () => _removeRow(i),
                                        icon: Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          size: 22.0,
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 48.0),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: [
                                    for (final col in _customColumns)
                                      SizedBox(
                                        width: 140.0,
                                        child: TextFormField(
                                          controller:
                                              _rows[i].ensureController(col),
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                fontSize: 13.0,
                                              ),
                                          decoration: _contactDecoration(col)
                                              .copyWith(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10.0,
                                              vertical: 10.0,
                                            ),
                                          ),
                                          textInputAction:
                                              TextInputAction.next,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      if (_rows.length > 50 && !_showAllContacts)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18.0,
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Showing first 50 of ${_rows.length} contacts for performance. All ${_rows.length} contacts will be included in the campaign.',
                                  style:
                                      FlutterFlowTheme.of(context).bodySmall,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _showAllContacts = true),
                                child: Text(
                                  'Show All',
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
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

  Widget _columnChip(
    String name, {
    required bool isDefault,
    VoidCallback? onDeleted,
  }) {
    return Chip(
      label: Text(
        '{{$name}}',
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: isDefault
              ? FlutterFlowTheme.of(context).primaryText
              : FlutterFlowTheme.of(context).primary,
        ),
      ),
      backgroundColor: isDefault
          ? FlutterFlowTheme.of(context).secondaryBackground
          : FlutterFlowTheme.of(context).primary.withOpacity(0.08),
      side: BorderSide(
        color: isDefault
            ? FlutterFlowTheme.of(context).alternate
            : FlutterFlowTheme.of(context).primary.withOpacity(0.35),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      visualDensity: VisualDensity.compact,
      deleteIcon: onDeleted != null
          ? Icon(
              Icons.close_rounded,
              size: 14.0,
              color: FlutterFlowTheme.of(context).secondaryText,
            )
          : null,
      onDeleted: onDeleted,
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
  final Map<String, TextEditingController> extraControllers = {};

  TextEditingController ensureController(String colName, [String initialValue = '']) {
    if (!extraControllers.containsKey(colName)) {
      extraControllers[colName] = TextEditingController(text: initialValue);
    }
    return extraControllers[colName]!;
  }

  void removeController(String colName) {
    extraControllers[colName]?.dispose();
    extraControllers.remove(colName);
  }

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    for (final c in extraControllers.values) {
      c.dispose();
    }
    extraControllers.clear();
  }
}
