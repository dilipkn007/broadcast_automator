import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/native_bridge.dart';

/// Opens the Smart Quick Paste bottom sheet allowing users to paste raw text
/// from WhatsApp, Notes, or Excel and automatically parse contacts.
Future<void> showQuickPasteSheet(
  BuildContext context, {
  required Function(List<Map<String, String>>) onContactsPasted,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QuickPasteSheet(onContactsPasted: onContactsPasted),
  );
}

class _QuickPasteSheet extends StatefulWidget {
  const _QuickPasteSheet({required this.onContactsPasted});

  final Function(List<Map<String, String>>) onContactsPasted;

  @override
  State<_QuickPasteSheet> createState() => _QuickPasteSheetState();
}

class _QuickPasteSheetState extends State<_QuickPasteSheet> {
  final _controller = TextEditingController();
  List<Map<String, String>> _parsedContacts = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {
      _parsedContacts = parseRawTextContacts(text);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      _onTextChanged(data.text!);
    }
  }

  void _confirmImport() {
    if (_parsedContacts.isEmpty) return;
    widget.onContactsPasted(_parsedContacts);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 20.0 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: theme.alternate,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),

            // Header
            Row(
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
                        Icons.content_paste_go_rounded,
                        color: theme.primary,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      'Quick Paste Contacts',
                      style: theme.titleMedium.override(
                        font: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                        ),
                        color: theme.primaryText,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.secondaryText),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 8.0),
            Text(
              'Paste text copied from WhatsApp, Notes, or Excel. Names and numbers are automatically extracted.',
              style: theme.bodySmall.override(
                color: theme.secondaryText,
                lineHeight: 1.3,
              ),
            ),

            const SizedBox(height: 12.0),

            // Paste from clipboard shortcut
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: Icon(Icons.paste_rounded, size: 16.0, color: theme.primary),
                label: Text(
                  'Paste from Clipboard',
                  style: GoogleFonts.inter(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                ),
              ),
            ),

            const SizedBox(height: 6.0),

            // Text Input
            TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              maxLines: 7,
              minLines: 4,
              style: theme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'e.g.\n9876543210\nJohn - +91 9876543210\nAlice: 9876543211\nBob, +15552345678',
                hintStyle: theme.bodySmall.override(
                  color: theme.secondaryText.withOpacity(0.6),
                ),
                filled: true,
                fillColor: theme.primaryBackground,
                contentPadding: const EdgeInsets.all(12.0),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.alternate, width: 1.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.primary, width: 2.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),

            const SizedBox(height: 12.0),

            // Detection status banner
            if (_parsedContacts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: theme.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: theme.success.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: theme.success, size: 16.0),
                        const SizedBox(width: 6.0),
                        Text(
                          '${_parsedContacts.length} contacts detected',
                          style: GoogleFonts.inter(
                            color: theme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    // Quick chips preview of first 5
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final c in _parsedContacts.take(5))
                            Container(
                              margin: const EdgeInsets.only(right: 6.0),
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                              decoration: BoxDecoration(
                                color: theme.secondaryBackground,
                                borderRadius: BorderRadius.circular(6.0),
                                border: Border.all(color: theme.alternate),
                              ),
                              child: Text(
                                c['name']!.isNotEmpty
                                    ? '${c['name']} (${c['phone']})'
                                    : c['phone']!,
                                style: theme.bodySmall.override(
                                  fontSize: 11.0,
                                ),
                              ),
                            ),
                          if (_parsedContacts.length > 5)
                            Text(
                              '+${_parsedContacts.length - 5} more',
                              style: theme.bodySmall.override(
                                color: theme.secondaryText,
                                fontSize: 11.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
            ] else if (_controller.text.trim().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: theme.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: theme.warning, size: 16.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'No valid phone numbers found yet. Make sure numbers have at least 7 digits.',
                        style: theme.bodySmall.override(
                          color: theme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
            ],

            // Action Buttons
            Row(
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
                    onPressed: _parsedContacts.isNotEmpty ? _confirmImport : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      disabledBackgroundColor: theme.primary.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      _parsedContacts.isEmpty
                          ? 'Add Contacts'
                          : 'Add (${_parsedContacts.length}) Contacts',
                      style: theme.bodyMedium.override(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
