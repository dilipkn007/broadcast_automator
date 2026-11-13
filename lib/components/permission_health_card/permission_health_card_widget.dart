import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class PermissionHealthCardWidget extends StatelessWidget {
  const PermissionHealthCardWidget({
    super.key,
    required this.isAccessibilityEnabled,
    required this.canDrawOverlays,
    required this.onEnableAccessibility,
    required this.onAllowOverlay,
    required this.onOpenGuide,
  });

  final bool isAccessibilityEnabled;
  final bool canDrawOverlays;
  final VoidCallback onEnableAccessibility;
  final VoidCallback onAllowOverlay;
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final allReady = isAccessibilityEnabled && canDrawOverlays;

    if (allReady) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: theme.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: theme.success.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: theme.success.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: theme.success,
                size: 20.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All permissions ready to send',
                    style: GoogleFonts.plusJakartaSans(
                      color: theme.primaryText,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Accessibility & Overlay are active and ready.',
                    style: GoogleFonts.inter(
                      color: theme.secondaryText,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20.0),
              onTap: onOpenGuide,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(
                  Icons.help_outline_rounded,
                  color: theme.secondaryText,
                  size: 20.0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final bothMissing = !isAccessibilityEnabled && !canDrawOverlays;
    final warningColor = theme.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: warningColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.0,
                height: 38.0,
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: warningColor,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bothMissing
                          ? 'Permissions needed to broadcast'
                          : (!isAccessibilityEnabled
                              ? 'Accessibility permission needed'
                              : 'Overlay permission needed'),
                      style: GoogleFonts.plusJakartaSans(
                        color: theme.primaryText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Text(
                      bothMissing
                          ? 'Enable accessibility and overlay permissions so the app can automate WhatsApp sends.'
                          : (!isAccessibilityEnabled
                              ? 'Required to automatically send broadcast messages to your WhatsApp contacts.'
                              : 'Required to display the floating progress bar & controls over WhatsApp.'),
                      style: GoogleFonts.inter(
                        color: theme.secondaryText,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          if (bothMissing) ...[
            _buildPermissionRow(
              context,
              title: 'Accessibility Service',
              subtitle: 'Automates message sending',
              icon: Icons.accessibility_new_rounded,
              isGranted: isAccessibilityEnabled,
              actionLabel: 'Enable',
              onTap: onEnableAccessibility,
            ),
            const SizedBox(height: 10.0),
            _buildPermissionRow(
              context,
              title: 'Display Over Other Apps',
              subtitle: 'Floating progress bar',
              icon: Icons.layers_rounded,
              isGranted: canDrawOverlays,
              actionLabel: 'Allow',
              onTap: onAllowOverlay,
            ),
            const SizedBox(height: 12.0),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !isAccessibilityEnabled
                        ? onEnableAccessibility
                        : onAllowOverlay,
                    icon: const Icon(Icons.settings_outlined, size: 16.0),
                    label: Text(
                      !isAccessibilityEnabled
                          ? 'Enable Accessibility'
                          : 'Allow Overlay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 10.0,
                      ),
                      shape: RoundedRectangleObserver(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                OutlinedButton.icon(
                  onPressed: onOpenGuide,
                  icon: const Icon(Icons.help_outline_rounded, size: 16.0),
                  label: Text(
                    'Guide',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryText,
                    side: BorderSide(
                      color: theme.alternate,
                      width: 1.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    shape: RoundedRectangleObserver(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (bothMissing)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onOpenGuide,
                icon: Icon(
                  Icons.help_outline_rounded,
                  size: 15.0,
                  color: theme.primary,
                ),
                label: Text(
                  'Open 2-step setup wizard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: theme.alternate,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.0,
            color: isGranted ? theme.success : theme.warning,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.primaryText,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          if (isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: theme.success,
                  size: 16.0,
                ),
                const SizedBox(width: 4.0),
                Text(
                  'Enabled',
                  style: GoogleFonts.inter(
                    color: theme.success,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                shape: RoundedRectangleObserver(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RoundedRectangleObserver extends RoundedRectangleBorder {
  const RoundedRectangleObserver({super.borderRadius});
}
