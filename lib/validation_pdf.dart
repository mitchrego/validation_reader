import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf_w;
import 'package:printing/printing.dart';
import 'package:validation_reader/validation_rule.dart';

class ValidationRulesPdfPreview extends StatelessWidget {
  final List<ValidationRule> rules;

  const ValidationRulesPdfPreview({super.key, required this.rules});

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final document = pdf_w.Document();

    document.addPage(
      pdf_w.MultiPage(
        pageFormat: format,
        header: (context) => pdf_w.Container(
          child: pdf_w.Row(
            mainAxisAlignment: pdf_w.MainAxisAlignment.spaceBetween,
            children: [
              pdf_w.Text(
                'Validation Rule Reader',
                style: pdf_w.TextStyle(
                  fontSize: 12,
                  fontWeight: pdf_w.FontWeight.bold,
                ),
              ),
              pdf_w.Text('${rules.length} selected rules'),
            ],
          ),
        ),
        build: (context) => [
          pdf_w.Text(
            'Validation Rules Summary',
            style: pdf_w.TextStyle(
              fontSize: 12,
              fontWeight: pdf_w.FontWeight.bold,
            ),
          ),
          pdf_w.SizedBox(height: 9),
          pdf_w.TableHelper.fromTextArray(
            headers: const ['ID', 'Description', 'Entity Types', 'Status'],
            data: rules
                .map(
                  (rule) => [
                    rule.id.toString(),
                    rule.description,
                    rule.entityTypeNames.join(', '),
                    rule.isEnabled ? 'Y' : 'N',
                  ],
                )
                .toList(),
            headerStyle: pdf_w.TextStyle(fontWeight: pdf_w.FontWeight.bold),
            cellStyle: const pdf_w.TextStyle(fontSize: 9),
            headerDecoration: const pdf_w.BoxDecoration(color: PdfColors.grey300),
            cellPadding: const pdf_w.EdgeInsets.all(6),
          ),
        ],
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
