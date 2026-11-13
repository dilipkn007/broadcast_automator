import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/native_bridge.dart';

class PermissionWizardDialog extends StatefulWidget {
  const PermissionWizardDialog({
    super.key,
    this.initialStep = 0,
    this.onPermissionsChanged,
  });

  final int initialStep;
  final VoidCallback? onPermissionsChanged;

  static const String prefKeyHasSeenWizard = 'has_seen_permission_wizard';

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onPermissionsChanged,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PermissionWizardDialog(
        onPermissionsChanged: onPermissionsChanged,
      ),
    );
  }

  static Future<bool> hasSeenWizard() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyHasSeenWizard) ?? false;
  }

  static Future<void> markWizardSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyHasSeenWizard, true);
  }

  @override
  State<PermissionWizardDialog> createState() => _PermissionWizardDialogState();
}

class _PermissionWizardDialogState extends State<PermissionWizardDialog>
    with WidgetsBindingObserver {
  int _currentStep = 0;
  bool _isAccessibilityEnabled = false;
  bool _canDrawOverlays = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    WidgetsBinding.instance.addObserver(this);
    PermissionWizardDialog.markWizardSeen();
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        _isLoading = false;

        // If both are already enabled and we are on step 0 or 1, move to all set
        if (_isAccessibilityEnabled && _canDrawOverlays && _currentStep < 2) {
          _currentStep = 2;
        }
      });

      widget.onPermissionsChanged?.call();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440.0),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _buildCurrentStep(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 20.0, 16.0, 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildStepDot(0, isCompleted: _isAccessibilityEnabled),
              const SizedBox(width: 6.0),
              _buildStepDot(1, isCompleted: _canDrawOverlays),
              const SizedBox(width: 6.0),
              _buildStepDot(2, isCompleted: _isAccessibilityEnabled && _canDrawOverlays),
              const SizedBox(width: 10.0),
              Text(
                _currentStep < 2
                    ? 'Step ${_currentStep + 1} of 2'
                    : 'Setup Complete',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.secondaryText, size: 20.0),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int stepIndex, {required bool isCompleted}) {
    final theme = FlutterFlowTheme.of(context);
    final isCurrent = _currentStep == stepIndex;

    Color color;
    if (isCompleted) {
      color = theme.success;
    } else if (isCurrent) {
      color = theme.primary;
    } else {
      color = theme.alternate;
    }

    return Container(
      width: isCurrent ? 24.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildAccessibilityStep(context);
      case 1:
        return _buildOverlayStep(context);
      case 2:
      default:
        return _buildCompletionStep(context);
    }
  }

  Widget _buildAccessibilityStep(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64.0,
            height: 64.0,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: theme.primary,
              size: 34.0,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Automated WhatsApp Sending',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: theme.primaryText,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Broadcast Automator uses Android Accessibility to automatically click Send in WhatsApp for each contact, so you don\'t have to send hundreds of messages manually.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: theme.secondaryText,
            fontSize: 13.0,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to enable:',
                style: GoogleFonts.plusJakartaSans(
                  color: theme.primaryText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12.0),
              _buildStepRow(
                '1',
                'Tap "Open Settings" below.',
              ),
              const SizedBox(height: 8.0),
              _buildStepRow(
                '2',
                'Find "WhatsApp Broadcast Automator" under Installed Apps.',
              ),
              const SizedBox(height: 8.0),
              _buildStepRow(
                '3',
                'Turn toggle ON and tap Allow.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        if (_isAccessibilityEnabled)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: theme.success, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  'Accessibility permission granted!',
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.success,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20.0),
        ElevatedButton(
          onPressed: () async {
            if (_isAccessibilityEnabled) {
              setState(() => _currentStep = 1);
            } else {
              await NativeBridge.openAccessibilitySettings();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: Text(
            _isAccessibilityEnabled ? 'Next: Overlay Permission' : 'Open Accessibility Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        TextButton(
          onPressed: () => setState(() => _currentStep = 1),
          child: Text(
            'Skip this step',
            style: GoogleFonts.inter(
              color: theme.secondaryText,
              fontSize: 13.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayStep(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64.0,
            height: 64.0,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.layers_rounded,
              color: theme.primary,
              size: 34.0,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Floating Progress Overlay',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: theme.primaryText,
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Displays a floating progress indicator over WhatsApp while sending so you can pause, resume, or cancel broadcasting anytime.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: theme.secondaryText,
            fontSize: 13.0,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20.0),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to enable:',
                style: GoogleFonts.plusJakartaSans(
                  color: theme.primaryText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12.0),
              _buildStepRow(
                '1',
                'Tap "Open Overlay Settings" below.',
              ),
              const SizedBox(height: 8.0),
              _buildStepRow(
                '2',
                'Toggle ON "Allow display over other apps".',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        if (_canDrawOverlays)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: theme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: theme.success, size: 18.0),
                const SizedBox(width: 8.0),
                Text(
                  'Overlay permission granted!',
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.success,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20.0),
        ElevatedButton(
          onPressed: () async {
            if (_canDrawOverlays) {
              setState(() => _currentStep = 2);
            } else {
              await NativeBridge.openOverlaySettings();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: Text(
            _canDrawOverlays ? 'Finish Setup' : 'Open Overlay Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: Text(
                'Back',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 13.0,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _currentStep = 2),
              child: Text(
                'Skip',
                style: GoogleFonts.inter(
                  color: theme.secondaryText,
                  fontSize: 13.0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionStep(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final allReady = _isAccessibilityEnabled && _canDrawOverlays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(
              color: (allReady ? theme.success : theme.warning).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              allReady ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: allReady ? theme.success : theme.warning,
              size: 44.0,
            ),
          ),
        ),
        const SizedBox(height: 18.0),
        Text(
          allReady ? 'You\'re All Set!' : 'Setup Summary',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: theme.primaryText,
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          allReady
              ? 'Permissions are configured! You can now import contacts, compose your message, and broadcast effortlessly.'
              : 'Some permissions are still pending. You can enable them anytime from the status banner at the top of the home screen.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: theme.secondaryText,
            fontSize: 13.0,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20.0),
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: theme.alternate, width: 1.0),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                'Accessibility Service',
                _isAccessibilityEnabled,
                onFix: () => NativeBridge.openAccessibilitySettings(),
              ),
              const Divider(height: 18.0),
              _buildSummaryRow(
                'Overlay Permission',
                _canDrawOverlays,
                onFix: () => NativeBridge.openOverlaySettings(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24.0),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: Text(
            'Get Started',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String title, bool isGranted, {required VoidCallback onFix}) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isGranted ? theme.success : theme.error,
          size: 20.0,
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: theme.primaryText,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (!isGranted)
          TextButton(
            onPressed: onFix,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            child: Text(
              'Enable',
              style: GoogleFonts.plusJakartaSans(
                color: theme.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Text(
            'Ready',
            style: GoogleFonts.inter(
              color: theme.success,
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildStepRow(String number, String text) {
    final theme = FlutterFlowTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.0,
          height: 20.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.plusJakartaSans(
              color: theme.primary,
              fontSize: 11.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: theme.primaryText,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
