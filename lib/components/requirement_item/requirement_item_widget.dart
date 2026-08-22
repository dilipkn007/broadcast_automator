import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'requirement_item_model.dart';
export 'requirement_item_model.dart';

class RequirementItemWidget extends StatefulWidget {
  const RequirementItemWidget({
    super.key,
    String? text,
  }) : this.text = text ?? 'Must contain \'Name\' and \'Phone\' columns';

  final String text;

  @override
  State<RequirementItemWidget> createState() => _RequirementItemWidgetState();
}

class _RequirementItemWidgetState extends State<RequirementItemWidget> {
  late RequirementItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RequirementItemModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          color: FlutterFlowTheme.of(context).primary,
          size: 16.0,
        ),
        Text(
          valueOrDefault<String>(
            widget!.text,
            'Must contain \'Name\' and \'Phone\' columns',
          ),
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(
                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                lineHeight: 1.4,
              ),
        ),
      ].divide(SizedBox(width: 8.0)),
    );
  }
}
