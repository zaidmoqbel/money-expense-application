import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';

class ExportService {
  static Future<String> exportTransactionsToCSV(List<TransactionModel> transactions) async {
    try {
      // Create CSV content
      final csvData = StringBuffer();

      // Add headers
      csvData.writeln('"ID","Type","Amount","Category","Account","Date","Notes","Created At"');

      // Add transaction data
      for (var transaction in transactions) {
        final row = [
          transaction.id,
          transaction.type,
          transaction.amount.toString(),
          transaction.category,
          transaction.account,
          transaction.date,
          transaction.notes?.replaceAll('"', '""') ?? '', // Escape quotes in notes
          transaction.createdAt,
        ];

        // Wrap fields containing commas or quotes in double quotes
        final escapedRow = row.map((field) {
          if (field.contains(',') || field.contains('"') || field.contains('\n')) {
            return '"${field.replaceAll('"', '""')}"';
          }
          return field;
        });

        csvData.writeln(escapedRow.join(','));
      }

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${directory.path}/$fileName';

      // Save the CSV file
      final file = File(filePath);
      await file.writeAsString(csvData.toString(), encoding: utf8);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export transactions: $e');
    }
  }
}
