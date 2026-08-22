import '/backend/backend.dart';
import '/components/button/button_widget.dart';
import '/components/requirement_item/requirement_item_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'empty_state_widget.dart' show EmptyStateWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class EmptyStateModel extends FlutterFlowModel<EmptyStateWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for Button.
  late ButtonModel buttonModel;
  // Model for RequirementItem.
  late RequirementItemModel requirementItemModel1;
  // Model for RequirementItem.
  late RequirementItemModel requirementItemModel2;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => ButtonModel());
    requirementItemModel1 = createModel(context, () => RequirementItemModel());
    requirementItemModel2 = createModel(context, () => RequirementItemModel());
  }

  @override
  void dispose() {
    buttonModel.dispose();
    requirementItemModel1.dispose();
    requirementItemModel2.dispose();
  }
}
