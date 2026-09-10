import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_widget;
import 'package:printing/printing.dart';
import 'package:validation_reader/validation_rule.dart';

class ValidationRulesPdfPreview extends StatelessWidget {
  final List<ValidationRule> rules;

  const ValidationRulesPdfPreview({super.key, required this.rules});

  pdf_widget.Widget _buildHeader() {
    return pdf_widget.Container(
      child: pdf_widget.Column(
        crossAxisAlignment: pdf_widget.CrossAxisAlignment.start,
        children: [
          pdf_widget.Row(
            mainAxisAlignment: pdf_widget.MainAxisAlignment.spaceBetween,
            children: [
              pdf_widget.Text(
                'Validation Rule Reader',
                style: pdf_widget.TextStyle(
                  fontSize: 12,
                  fontWeight: pdf_widget.FontWeight.bold,
                ),
              ),
              pdf_widget.Text('${rules.length} selected rules'),
            ],
          ),
          pdf_widget.SizedBox(height: 4),
          pdf_widget.Row(
            mainAxisAlignment: pdf_widget.MainAxisAlignment.spaceBetween,
            children: [
              pdf_widget.Text('Validation Summary'),
              pdf_widget.Text(
                'Generated: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                style: const pdf_widget.TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pdf_widget.Widget _buildRuleField(String label, dynamic value, double width) {
    return pdf_widget.Container(
      width: width,
      padding: const pdf_widget.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pdf_widget.Column(
        crossAxisAlignment: pdf_widget.CrossAxisAlignment.start,
        children: [
          pdf_widget.Text(
            label,
            style: pdf_widget.TextStyle(
              fontSize: 7,
              fontWeight: pdf_widget.FontWeight.bold,
            ),
          ),
          pdf_widget.Text(
            value.toString(),
            style: const pdf_widget.TextStyle(fontSize: 8),
            softWrap: true,
          ),
        ],
      ),
    );
  }

  pdf_widget.Widget _buildRuleBlock(ValidationRule rule) {
    final entityTypes = rule.entityTypeNames.isEmpty ? '—' : rule.entityTypeNames.join(', ');

    return pdf_widget.Container(
      margin: const pdf_widget.EdgeInsets.only(bottom: 12),
      padding: const pdf_widget.EdgeInsets.all(6),
      decoration: pdf_widget.BoxDecoration(
        border: pdf_widget.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pdf_widget.Column(
        crossAxisAlignment: pdf_widget.CrossAxisAlignment.start,
        children: [
          pdf_widget.Row(
            crossAxisAlignment: pdf_widget.CrossAxisAlignment.start,
            children: [
              _buildRuleField('ID', rule.id, 40),
              _buildRuleField('Description', rule.description, 360),
              _buildRuleField('Status', rule.isEnabled ? 'Enabled' : 'Disabled', 90),
            ],
          ),
          pdf_widget.Container(
            width: 340,
            padding: const pdf_widget.EdgeInsets.only(top: 4, left: 42),
            child: pdf_widget.Text(
              'Error: ${rule.errorMessage ?? " --- "}',
              style: const pdf_widget.TextStyle(fontSize: 8, fontStyle: pdf_widget.FontStyle.italic),
              softWrap: true,
            ),
          ),
          pdf_widget.SizedBox(height: 6),
          pdf_widget.Row(
            crossAxisAlignment: pdf_widget.CrossAxisAlignment.start,
            children: [
              _buildRuleField('Create', rule.runOnCreate ? 'Y' : 'N', 60),
              _buildRuleField('Update', rule.runOnUpdate ? 'Y' : 'N', 60),
              _buildRuleField('Delete', rule.runOnDelete ? 'Y' : 'N', 60),
              _buildRuleField('Entity Types', entityTypes, 220),
            ],
          ),
          pdf_widget.SizedBox(height: 8),
          pdf_widget.Container(
            width: 340,
            padding: const pdf_widget.EdgeInsets.all(6),
            decoration: pdf_widget.BoxDecoration(
              border: pdf_widget.Border.all(color: PdfColors.grey500, width: 0.8),
              color: PdfColors.grey100,
            ),
            child: pdf_widget.Text(
              rule.dslCondition,
              style: pdf_widget.TextStyle(
                font: pdf_widget.Font.courier(),
                fontSize: 7,
              ),
              textAlign: pdf_widget.TextAlign.left,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  List<pdf_widget.Widget> _buildBody() {
    final body = <pdf_widget.Widget>[];

    body.add(pdf_widget.SizedBox(height: 9));

    for (final rule in rules) {
      body.add(pdf_widget.NewPage(freeSpace: 100));
      body.add(pdf_widget.Inseparable(child: _buildRuleBlock(rule)));
    }

    return body;
  }

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final document = pdf_widget.Document();

    document.addPage(
      pdf_widget.MultiPage(
        pageFormat: format,
        header: (context) => _buildHeader(),
        build: (context) => _buildBody(),
      ),
    );

    return document.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Rules Summary')),
      body: PdfPreview(
        build: _buildPdf,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        pdfFileName: 'validation-rules-summary.pdf',
      ),
    );
  }
}
