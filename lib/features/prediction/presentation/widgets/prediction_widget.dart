// Feature: Prediction
// Layer: Presentation

import 'package:flutter/material.dart';

import 'prediction_card.dart';

@Deprecated('Use PredictionCard instead.')
class PredictionWidget extends StatelessWidget {
  const PredictionWidget({
    super.key,
    required this.month,
    required this.currentSpent,
  });

  final DateTime month;
  final double currentSpent;

  @override
  Widget build(BuildContext context) {
    return const PredictionCard();
  }
}
