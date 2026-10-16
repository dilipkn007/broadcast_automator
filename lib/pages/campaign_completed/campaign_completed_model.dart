import '/components/button/button_widget.dart';
import '/components/report_stat_card/report_stat_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'campaign_completed_widget.dart' show CampaignCompletedWidget;
import 'package:flutter/material.dart';

class CampaignCompletedModel extends FlutterFlowModel<CampaignCompletedWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ReportStatCard.
  late ReportStatCardModel reportStatCardModel1;
  // Model for ReportStatCard.
  late ReportStatCardModel reportStatCardModel2;
  // Model for ReportStatCard.
  late ReportStatCardModel reportStatCardModel3;
  // Model for ReportStatCard.
  late ReportStatCardModel reportStatCardModel4;
  // Model for Button.
  late ButtonModel buttonModel1;
  // Model for Button.
  late ButtonModel buttonModel2;
  // Model for Button.
  late ButtonModel buttonModel3;
  // Model for Button.
  late ButtonModel buttonModel4;

  @override
  void initState(BuildContext context) {
    reportStatCardModel1 = createModel(context, () => ReportStatCardModel());
    reportStatCardModel2 = createModel(context, () => ReportStatCardModel());
    reportStatCardModel3 = createModel(context, () => ReportStatCardModel());
    reportStatCardModel4 = createModel(context, () => ReportStatCardModel());
    buttonModel1 = createModel(context, () => ButtonModel());
    buttonModel2 = createModel(context, () => ButtonModel());
    buttonModel3 = createModel(context, () => ButtonModel());
    buttonModel4 = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    reportStatCardModel1.dispose();
    reportStatCardModel2.dispose();
    reportStatCardModel3.dispose();
    reportStatCardModel4.dispose();
    buttonModel1.dispose();
    buttonModel2.dispose();
    buttonModel3.dispose();
    buttonModel4.dispose();
  }
}
