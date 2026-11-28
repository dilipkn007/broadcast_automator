import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/native_bridge.dart';
import '/index.dart';

/// Shows an interactive bottom sheet to create a new campaign using the contacts
/// from a historical / completed campaign.
Future<void> showCreateCampaignFromHistorySheet(
  BuildContext context, {
  required String sourceCampaignId,
  String? sourceCampaignName,
  List<Map<String, dynamic>>? preloadedContacts,
}) async {
  if (sourceCampaignId.isEmpty) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CreateCampaignFromHistoryModal(
      sourceCampaignId: sourceCampaignId,
      sourceCampaignName: sourceCampaignName,
      preloadedContacts: preloadedContacts,
    ),
  );
}

/// Shows a bottom sheet to pick any historical campaign and import its contacts.
Future<void> showSelectHistoricalCampaignSheet(
  BuildContext context, {
  required Function(CampaignsRecord campaign) onCampaignSelected,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SelectHistoricalCampaignModal(
      onCampaignSelected: onCampaignSelected,
    ),
  );
}

class _CreateCampaignFromHistoryModal extends StatefulWidget {
  const _CreateCampaignFromHistoryModal({
    required this.sourceCampaignId,
    this.sourceCampaignName,
    this.preloadedContacts,
  });

  final String sourceCampaignId;
  final String? sourceCampaignName;
  final List<Map<String, dynamic>>? preloadedContacts;

  @override
  State<_CreateCampaignFromHistoryModal> createState() =>
      _CreateCampaignFromHistoryModalState();
}

class _CreateCampaignFromHistoryModalState
    extends State<_CreateCampaignFromHistoryModal> {
  late TextEditingController _nameController;
  bool _loading = true;
  bool _submitting = false;
  String _selectedFilter = 'all'; // 'all', 'sent', 'failed'

  List<Map<String, dynamic>> _allContacts = [];
  String _campaignName = '';

  @override
  void initState() {
    super.initState();
    _campaignName = widget.sourceCampaignName?.trim() ?? '';
    final defaultTitle = _campaignName.isNotEmpty
        ? '$_campaignName (Follow-up)'
        : 'New Broadcast List';
    _nameController = TextEditingController(text: defaultTitle);

    _initContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initContacts() async {
    if (widget.preloadedContacts != null &&
        widget.preloadedContacts!.isNotEmpty) {
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final c in widget.preloadedContacts!) {
        final phone = (c['phone'] ?? '').toString();
        final norm = normalizeWhatsAppNumber(phone);
        final name = (c['name'] ?? '').toString().trim();
        final key = norm.isNotEmpty ? norm : name.toLowerCase();
        if (key.isNotEmpty && seen.contains(key)) continue;
        if (key.isNotEmpty) seen.add(key);
        unique.add(Map<String, dynamic>.from(c));
      }
      unique.sort((a, b) {
        final nameA = (a['name']?.toString() ?? '').trim().toLowerCase();
        final nameB = (b['name']?.toString() ?? '').trim().toLowerCase();
        if (nameA.isEmpty && nameB.isEmpty) return 0;
        if (nameA.isEmpty) return 1;
        if (nameB.isEmpty) return -1;
        return nameA.compareTo(nameB);
      });

      setState(() {
        _allContacts = unique;
        _loading = false;
      });
      return;
    }

    try {
      if (_campaignName.isEmpty) {
        final cDoc =
            await CampaignsRecord.getDocumentOnce(widget.sourceCampaignId);
        if (cDoc != null) {
          _campaignName = cDoc.name;
          if (_nameController.text == 'New Broadcast List') {
            _nameController.text = '${cDoc.name} (Follow-up)';
          }
        }
      }

      final cList = await queryContactsRecordOnce(
        queryBuilder: (q) =>
            q.where('campaign_id', isEqualTo: widget.sourceCampaignId),
      );

      if (!mounted) return;
      final seen = <String>{};
      final unique = <Map<String, dynamic>>[];
      for (final c in cList) {
        final norm = normalizeWhatsAppNumber(c.phone);
        final key = norm.isNotEmpty ? norm : c.name.trim().toLowerCase();
        if (key.isNotEmpty && seen.contains(key)) continue;
        if (key.isNotEmpty) seen.add(key);
        unique.add({
          'name': c.name.isEmpty ? 'Unknown' : c.name,
          'phone': norm.isNotEmpty ? norm : c.phone,
          'status': c.status.isEmpty ? 'Pending' : c.status,
        });
      }
      unique.sort((a, b) {
        final nameA = (a['name']?.toString() ?? '').trim().toLowerCase();
        final nameB = (b['name']?.toString() ?? '').trim().toLowerCase();
        if (nameA.isEmpty && nameB.isEmpty) return 0;
        if (nameA.isEmpty) return 1;
        if (nameB.isEmpty) return -1;
        return nameA.compareTo(nameB);
      });

      setState(() {
        _allContacts = unique;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnackbar(context, 'Could not fetch contacts: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredContacts {
    if (_selectedFilter == 'sent') {
      return _allContacts
          .where((c) => (c['status'] ?? '').trim().toLowerCase() == 'sent')
          .toList();
    }
    if (_selectedFilter == 'failed') {
      return _allContacts
          .where((c) =>
              (c['status'] ?? '').trim().toLowerCase() == 'failed' ||
              (c['status'] ?? '').trim().toLowerCase() == 'skipped')
          .toList();
    }
    return _allContacts;
  }

  Future<void> _createCampaignNow() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnackbar(context, 'Please enter a campaign name');
      return;
    }

    final contactsToUse = _filteredContacts;
    if (contactsToUse.isEmpty) {
      showSnackbar(context, 'No contacts match the selected filter');
      return;
    }

    setState(() => _submitting = true);

    try {
      final campaignInsert = await supabase
          .from(CampaignsRecord.tableName)
          .insert(createCampaignsRecordData(
            deviceId: FFAppState().userDeviceUuid,
            name: name,
            contactCount: contactsToUse.length,
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

      final newCampaignId = campaignInsert['id'].toString();

      await supabase.from(ContactsRecord.tableName).insert(
            contactsToUse
                .map((contact) => createContactsRecordData(
                      campaignId: newCampaignId,
                      name: contact['name']?.toString() ?? '',
                      phone: contact['phone']?.toString() ?? '',
                      status: 'Pending',
                      extraFields: contact['extra_fields'] is Map
                          ? (contact['extra_fields'] as Map)
                              .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
                          : null,
                    ))
                .toList(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      showSnackbar(context,
          'Campaign "$name" created with ${contactsToUse.length} contacts!');

      context.pushNamed(
        BroadcastDetailsWidget.routeName,
        queryParameters: {
          'campaignId': serializeParam(newCampaignId, ParamType.String),
        }.withoutNulls,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showSnackbar(context, 'Failed to create campaign: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sentCount = _allContacts
        .where((c) => (c['status'] ?? '').trim().toLowerCase() == 'sent')
        .length;
    final failedCount = _allContacts
        .where((c) =>
            (c['status'] ?? '').trim().toLowerCase() == 'failed' ||
            (c['status'] ?? '').trim().toLowerCase() == 'skipped')
        .length;

    final contactsToUse = _filteredContacts;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20.0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44.0,
                height: 5.0,
                margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(999.0),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 16.0, 12.0),
              child: Row(
                children: [
                  Container(
                    width: 42.0,
                    height: 42.0,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Icon(
                      Icons.group_add_rounded,
                      color: theme.primary,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Campaign from Contacts',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.primaryText,
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          _campaignName.isNotEmpty
                              ? 'From history: "$_campaignName"'
                              : 'Reusing historical campaign contacts',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: theme.secondaryText,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.secondaryText,
                      size: 22.0,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1.0),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    // Campaign Name field
                    Text(
                      'New Campaign Name',
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.primaryText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(
                        color: theme.primaryText,
                        fontSize: 14.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter new campaign name',
                        hintStyle: GoogleFonts.inter(
                          color: theme.secondaryText,
                          fontSize: 14.0,
                        ),
                        filled: true,
                        fillColor: theme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0, vertical: 12.0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                            color: theme.alternate,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(
                            color: theme.primary,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Filter Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Contacts to Include',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.primaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${contactsToUse.length} contacts selected',
                          style: GoogleFonts.inter(
                            color: theme.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('All (${_allContacts.length})'),
                            selected: _selectedFilter == 'all',
                            selectedColor: theme.primary,
                            backgroundColor: theme.surfaceVariant,
                            labelStyle: GoogleFonts.inter(
                              color: _selectedFilter == 'all'
                                  ? Colors.white
                                  : theme.primaryText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedFilter = 'all');
                            },
                          ),
                          if (sentCount > 0) ...[
                            const SizedBox(width: 8.0),
                            ChoiceChip(
                              label: Text('Sent Only ($sentCount)'),
                              selected: _selectedFilter == 'sent',
                              selectedColor: theme.success,
                              backgroundColor: theme.surfaceVariant,
                              labelStyle: GoogleFonts.inter(
                                color: _selectedFilter == 'sent'
                                    ? Colors.white
                                    : theme.primaryText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (val) {
                                if (val)
                                  setState(() => _selectedFilter = 'sent');
                              },
                            ),
                          ],
                          if (failedCount > 0) ...[
                            const SizedBox(width: 8.0),
                            ChoiceChip(
                              label: Text('Failed/Skipped ($failedCount)'),
                              selected: _selectedFilter == 'failed',
                              selectedColor: theme.error,
                              backgroundColor: theme.surfaceVariant,
                              labelStyle: GoogleFonts.inter(
                                color: _selectedFilter == 'failed'
                                    ? Colors.white
                                    : theme.primaryText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (val) {
                                if (val)
                                  setState(() => _selectedFilter = 'failed');
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Contact Preview Box
                    Container(
                      height: 160.0,
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: theme.alternate, width: 1.0),
                      ),
                      child: contactsToUse.isEmpty
                          ? Center(
                              child: Text(
                                'No contacts match this filter',
                                style: GoogleFonts.inter(
                                  color: theme.secondaryText,
                                  fontSize: 13.0,
                                ),
                              ),
                            )
                          : Scrollbar(
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                itemCount: contactsToUse.length,
                                separatorBuilder: (_, __) =>
                                    Divider(height: 1.0, color: theme.alternate),
                                itemBuilder: (context, idx) {
                                  final c = contactsToUse[idx];
                                  final name = c['name'] ?? 'Contact';
                                  final phone = c['phone'] ?? '';
                                  final initial = name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '#';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14.0,
                                          backgroundColor:
                                              theme.primary.withOpacity(0.12),
                                          child: Text(
                                            initial,
                                            style: GoogleFonts.inter(
                                              color: theme.primary,
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10.0),
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: theme.primaryText,
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          phone,
                                          style: GoogleFonts.inter(
                                            color: theme.secondaryText,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 24.0),

                    // Primary Action: Create Campaign Now
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _createCampaignNow,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18.0,
                                height: 18.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.rocket_launch_rounded,
                                size: 19.0),
                        label: Text(
                          _submitting
                              ? 'Creating Campaign...'
                              : 'Create Campaign Now',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0),

                    // Secondary Action: Customize Contacts in Editor
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                context.pushNamed(
                                  CreateBroadcastWidget.routeName,
                                  queryParameters: {
                                    'sourceCampaignId': serializeParam(
                                      widget.sourceCampaignId,
                                      ParamType.String,
                                    ),
                                  }.withoutNulls,
                                );
                              },
                        icon: Icon(Icons.edit_note_rounded,
                            size: 19.0, color: theme.primaryText),
                        label: Text(
                          'Customize Contacts in Full Editor',
                          style: GoogleFonts.inter(
                            color: theme.primaryText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13.0),
                          side: BorderSide(color: theme.alternate, width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
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
    );
  }
}

class _SelectHistoricalCampaignModal extends StatefulWidget {
  const _SelectHistoricalCampaignModal({
    required this.onCampaignSelected,
  });

  final Function(CampaignsRecord campaign) onCampaignSelected;

  @override
  State<_SelectHistoricalCampaignModal> createState() =>
      _SelectHistoricalCampaignModalState();
}

class _SelectHistoricalCampaignModalState
    extends State<_SelectHistoricalCampaignModal> {
  bool _loading = true;
  List<CampaignsRecord> _campaigns = [];

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;
    try {
      return DateFormat('MMM d, yyyy').parse(trimmed);
    } catch (_) {}
    return null;
  }

  String _formatDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final dt = DateTime.tryParse(trimmed);
    if (dt != null) {
      return DateFormat('MMM d, yyyy').format(dt.toLocal());
    }
    return raw;
  }

  Future<void> _loadCampaigns() async {
    try {
      final list = await queryCampaignsRecordOnce(
        queryBuilder: (q) => q.orderBy('created_at', descending: true),
      );
      final sorted = List<CampaignsRecord>.from(list);
      sorted.sort((a, b) {
        final dateA = _parseDate(a.createdAt);
        final dateB = _parseDate(b.createdAt);
        if (dateA != null && dateB != null) {
          final cmp = dateB.compareTo(dateA);
          if (cmp != 0) return cmp;
        } else if (dateA != null) {
          return -1;
        } else if (dateB != null) {
          return 1;
        }
        return b.id.compareTo(a.id);
      });
      if (!mounted) return;
      setState(() {
        _campaigns = sorted;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20.0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44.0,
                height: 5.0,
                margin: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(999.0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 16.0, 12.0),
              child: Row(
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: theme.primary,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Import from Past Campaign',
                          style: GoogleFonts.plusJakartaSans(
                            color: theme.primaryText,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Select any historical campaign to load its contacts',
                          style: GoogleFonts.inter(
                            color: theme.secondaryText,
                            fontSize: 12.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.secondaryText,
                      size: 22.0,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1.0),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_campaigns.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 48.0, horizontal: 24.0),
                child: Center(
                  child: Text(
                    'No historical campaigns found yet.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: theme.secondaryText,
                      fontSize: 14.0,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _campaigns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10.0),
                  itemBuilder: (context, idx) {
                    final c = _campaigns[idx];
                    final isCompleted =
                        c.status.trim().toLowerCase() == 'completed';

                    return InkWell(
                      borderRadius: BorderRadius.circular(14.0),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onCampaignSelected(c);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: theme.alternate,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? theme.success.withOpacity(0.12)
                                    : theme.primary.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Icon(
                                isCompleted
                                    ? Icons.task_alt_rounded
                                    : Icons.campaign_rounded,
                                color: isCompleted
                                    ? theme.success
                                    : theme.primary,
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name.isEmpty ? 'Untitled' : c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: theme.primaryText,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Row(
                                    children: [
                                      Text(
                                        '${c.contactCount} contacts',
                                        style: GoogleFonts.inter(
                                          color: theme.secondaryText,
                                          fontSize: 12.0,
                                        ),
                                      ),
                                      if (c.createdAt.isNotEmpty) ...[
                                        Text(
                                          ' • ${_formatDate(c.createdAt)}',
                                          style: GoogleFonts.inter(
                                            color: theme.secondaryText,
                                            fontSize: 12.0,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? theme.success.withOpacity(0.12)
                                    : theme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                c.status.isNotEmpty ? c.status : 'Ready',
                                style: GoogleFonts.inter(
                                  color: isCompleted
                                      ? theme.success
                                      : theme.primary,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14.0,
                              color: theme.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
