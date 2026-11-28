import '/backend/backend.dart';
import '/components/button/button_widget.dart';
import '/components/slider/slider_widget.dart';
import '/components/switch_component/switch_component_widget.dart';
import '/components/text_field/text_field_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'broadcast_details_widget.dart' show BroadcastDetailsWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BroadcastDetailsModel extends FlutterFlowModel<BroadcastDetailsWidget> {
  ///  Local state fields for this page.

  String? messageBody;

  int? delaySeconds;

  int? preSendDelaySeconds;

  bool? randomizeDelay;

  bool? skipInvalid = true;

  bool? autoRetry = false;

  bool? autoPauseEnabled;

  int? autoPauseMinutes;

  TextEditingController? autoPauseMinutesTextController;
  FocusNode? autoPauseMinutesFocusNode;

  bool? pauseAfterMessagesEnabled;

  int? pauseAfterMessages;

  TextEditingController? pauseAfterMessagesTextController;
  FocusNode? pauseAfterMessagesFocusNode;

  bool? autoResumeEnabled;

  int? autoResumeMinutes;

  TextEditingController? autoResumeMinutesTextController;
  FocusNode? autoResumeMinutesFocusNode;

  ///  State fields for stateful widgets in this page.

  // Model for TextField.
  late TextFieldModel textFieldModel;
  // Model for Slider.
  late SliderModel sliderModel;
  // Model for Pre-Send Delay Slider.
  late SliderModel preSendDelaySliderModel;
  // Model for Switch.
  late SwitchComponentModel switchModel1;
  // Model for Switch.
  late SwitchComponentModel switchModel2;
  // Model for Switch.
  late SwitchComponentModel switchModelAutoPause;
  late SwitchComponentModel switchModelPauseMessages;
  late SwitchComponentModel switchModelAutoResume;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;

  @override
  void initState(BuildContext context) {
    textFieldModel = createModel(context, () => TextFieldModel());
    sliderModel = createModel(context, () => SliderModel());
    preSendDelaySliderModel = createModel(context, () => SliderModel());
    switchModel1 = createModel(context, () => SwitchComponentModel());
    switchModel2 = createModel(context, () => SwitchComponentModel());
    switchModelAutoPause = createModel(context, () => SwitchComponentModel());
    switchModelPauseMessages = createModel(context, () => SwitchComponentModel());
    switchModelAutoResume = createModel(context, () => SwitchComponentModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    autoPauseMinutesTextController?.dispose();
    autoPauseMinutesFocusNode?.dispose();
    pauseAfterMessagesTextController?.dispose();
    pauseAfterMessagesFocusNode?.dispose();
    autoResumeMinutesTextController?.dispose();
    autoResumeMinutesFocusNode?.dispose();
    textFieldModel.dispose();
    sliderModel.dispose();
    preSendDelaySliderModel.dispose();
    switchModel1.dispose();
    switchModel2.dispose();
    switchModelAutoPause.dispose();
    switchModelPauseMessages.dispose();
    switchModelAutoResume.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
  }
}
