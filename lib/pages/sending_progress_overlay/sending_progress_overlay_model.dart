import '/backend/backend.dart';
import '/components/button/button_widget.dart';
import '/components/progress_stat_item/progress_stat_item_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import 'sending_progress_overlay_widget.dart' show SendingProgressOverlayWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

class SendingProgressOverlayModel
    extends FlutterFlowModel<SendingProgressOverlayWidget> {
  ///  Local state fields for this page.

  int? currentIndex = 0;

  bool? isPaused = false;

  ///  State fields for stateful widgets in this page.

  // Model for ProgressStatItem.
  late ProgressStatItemModel progressStatItemModel1;
  // Model for ProgressStatItem.
  late ProgressStatItemModel progressStatItemModel2;
  // Model for ProgressStatItem.
  late ProgressStatItemModel progressStatItemModel3;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    progressStatItemModel1 =
        createModel(context, () => ProgressStatItemModel());
    progressStatItemModel2 =
        createModel(context, () => ProgressStatItemModel());
    progressStatItemModel3 =
        createModel(context, () => ProgressStatItemModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    progressStatItemModel1.dispose();
    progressStatItemModel2.dispose();
    progressStatItemModel3.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
