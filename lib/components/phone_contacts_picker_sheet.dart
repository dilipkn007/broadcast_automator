import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/native_bridge.dart';

/// Opens the Phone Contacts Multi-Picker bottom sheet.
Future<void> showPhoneContactsPickerSheet(
  BuildContext context, {
  required Function(List<Map<String, String>>) onContactsSelected,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PhoneContactsPickerSheet(onContactsSelected: onContactsSelected),
  );
}

class _PhoneContactsPickerSheet extends StatefulWidget {
  const _PhoneContactsPickerSheet({required this.onContactsSelected});

  final Function(List<Map<String, String>>) onContactsSelected;

  @override
  State<_PhoneContactsPickerSheet> createState() => _PhoneContactsPickerSheetState();
}

class _PhoneContactsPickerSheetState extends State<_PhoneContactsPickerSheet> {
  final _searchController = TextEditingController();
  List<Map<String, String>> _allContacts = [];
  List<Map<String, String>> _filteredContacts = [];
  final Set<String> _selectedPhones = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await NativeBridge.getPhoneContacts();
      if (!mounted) return;
      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'permission_denied') {
          _errorMessage =
              'Contacts permission is required to select from your phonebook. Please grant permission when prompted or pick a contact directly.';
        } else {
          _errorMessage = 'Could not load contacts: ${e.message}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading contacts: $e';
      });
    }
  }

  Future<void> _pickSingleContactFallback() async {
    try {
      final contact = await NativeBridge.pickSingleContact();
      if (contact != null && mounted) {
        widget.onContactsSelected([contact]);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick contact: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        _filteredContacts = _allContacts.where((c) {
          final name = (c['name'] ?? '').toLowerCase();
          final phone = (c['phone'] ?? '').toLowerCase();
          return name.contains(q) || phone.contains(q);
        }).toList();
      }
    });
  }

  void _selectAllFiltered() {
    setState(() {
      for (final c in _filteredContacts) {
        final phone = c['phone'];
        if (phone != null && phone.isNotEmpty) {
          _selectedPhones.add(phone);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPhones.clear();
    });
  }

  void _toggleContact(String phone) {
    setState(() {
      if (_selectedPhones.contains(phone)) {
        _selectedPhones.remove(phone);
      } else {
        _selectedPhones.add(phone);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedPhones.isEmpty) return;
    final selectedList = _allContacts
        .where((c) => _selectedPhones.contains(c['phone']))
        .toList();
    widget.onContactsSelected(selectedList);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.85;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                color: theme.alternate,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Icon(
                        Icons.contacts_rounded,
                        color: theme.primary,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Contacts',
                          style: theme.titleMedium.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                            ),
                            color: theme.primaryText,
                          ),
                        ),
                        if (!_isLoading && _errorMessage == null)
                          Text(
                            '${_selectedPhones.length} of ${_allContacts.length} selected',
                            style: theme.bodySmall.override(
                              color: theme.secondaryText,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
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

          const SizedBox(height: 10.0),

          // Search Bar
          if (!_isLoading && _errorMessage == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: theme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search by name or number...',
                  hintStyle: theme.bodySmall.override(
                    color: theme.secondaryText.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: theme.secondaryText, size: 20.0),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18.0, color: theme.secondaryText),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.primaryBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.alternate, width: 1.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),

            // Select all / Deselect all
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _selectAllFiltered,
                    icon: Icon(Icons.select_all_rounded, size: 16.0, color: theme.primary),
                    label: Text(
                      'Select All (${_filteredContacts.length})',
                      style: GoogleFonts.inter(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                  ),
                  if (_selectedPhones.isNotEmpty) ...[
                    const SizedBox(width: 8.0),
                    TextButton.icon(
                      onPressed: _deselectAll,
                      icon: Icon(Icons.deselect_rounded, size: 16.0, color: theme.secondaryText),
                      label: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w500,
                          color: theme.secondaryText,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 8.0),
          ],

          // Content body
          Expanded(
            child: _buildBody(theme),
          ),

          // Bottom sticky confirmation
          Container(
            padding: EdgeInsetsDirectional.fromSTEB(
              20.0,
              12.0,
              20.0,
              12.0 + mediaQuery.padding.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8.0,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      side: BorderSide(color: theme.alternate),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedPhones.isNotEmpty ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      disabledBackgroundColor: theme.primary.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      _selectedPhones.isEmpty
                          ? 'Select Contacts'
                          : 'Add (${_selectedPhones.length}) Contacts',
                      style: theme.bodyMedium.override(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  Widget _buildBody(FlutterFlowTheme theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary),
            const SizedBox(height: 16.0),
            Text(
              'Loading contacts from phone...',
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_rounded, size: 48.0, color: theme.secondaryText),
              const SizedBox(height: 12.0),
              Text(
                'Permission Required',
                style: theme.titleMedium.override(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 20.0),
              ElevatedButton.icon(
                onPressed: _loadContacts,
                icon: const Icon(Icons.refresh_rounded, size: 18.0),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10.0),
              TextButton.icon(
                onPressed: _pickSingleContactFallback,
                icon: const Icon(Icons.person_search_rounded, size: 18.0),
                label: const Text('Pick Single Contact via Android System'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchController.text.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 44.0,
                color: theme.secondaryText,
              ),
              const SizedBox(height: 10.0),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No matching contacts found'
                    : 'No contacts with phone numbers found',
                style: theme.bodyMedium.override(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredContacts.length,
      separatorBuilder: (_, __) => Divider(
        height: 1.0,
        indent: 68.0,
        color: theme.alternate.withOpacity(0.5),
      ),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final name = (contact['name'] ?? '').trim();
        final phone = (contact['phone'] ?? '').trim();
        final isSelected = _selectedPhones.contains(phone);

        final initial = name.isNotEmpty
            ? name.characters.first.toUpperCase()
            : '#';

        return InkWell(
          onTap: () => _toggleContact(phone),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20.0,
                  backgroundColor: isSelected
                      ? theme.primary
                      : theme.primary.withOpacity(0.12),
                  child: Text(
                    initial,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      color: isSelected ? Colors.white : theme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Unknown Name',
                        style: theme.bodyMedium.override(
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        phone,
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleContact(phone),
                  activeColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
