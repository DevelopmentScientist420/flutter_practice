import 'package:intl/intl.dart';

class Expense {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final String type;
  final String accountNumber;
  final String currency;

  Expense({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.accountNumber,
    required this.currency,
  });

  factory Expense.fromCsvRow(List<String> row, Map<String, int> columnIndices) {
    try {
      return Expense(
        id: row[columnIndices['ID'] ?? 0],
        date: _parseDate(row[columnIndices['date']!]),
        description: row[columnIndices['description']!],
        amount: double.parse(row[columnIndices['amount']!]),
        type: row[columnIndices['type']!],
        accountNumber: row[columnIndices['account_number']!],
        currency: row[columnIndices['currency']!],
      );
    } catch (e) {
      throw Exception('Error parsing expense row: ${row.join(", ")}. Error: $e');
    }
  }

  // Helper method to create column index mapping from header row
  static Map<String, int> createColumnMapping(List<String> headerRow) {
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headerRow.length; i++) {
      String originalColumn = headerRow[i].trim();
      String columnName = originalColumn.toLowerCase();
      
      // Handle the first unnamed column (numbers) or empty column
      if (columnName.isEmpty || columnName == '' || RegExp(r'^\d+$').hasMatch(originalColumn)) {
        columnIndices['ID'] = i;
      } else {
        // Normalize common column name variations
        if (columnName == 'account number' || columnName == 'accountnumber') {
          columnName = 'account_number';
        }
        columnIndices[columnName] = i;
      }
    }
    return columnIndices;
  }

  static DateTime _parseDate(String dateString) {
    try {
      // First try ISO format (YYYY-MM-DD) which is most common
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        // Then try DD/MM/YYYY format
        final DateFormat formatter = DateFormat('dd/MM/yyyy');
        return formatter.parse(dateString);
      } catch (e2) {
        throw Exception('Invalid date format: $dateString. Expected YYYY-MM-DD or DD/MM/YYYY');
      }
    }
  }

  @override
  String toString() {
    return 'Expense(id: $id, date: $date, description: $description, amount: $amount, type: $type, accountNumber: $accountNumber, currency: $currency)';
  }
}

class MonthlyExpense {
  final DateTime month;
  final double totalAmount;
  final List<Expense> expenses;

  MonthlyExpense({
    required this.month,
    required this.totalAmount,
    required this.expenses,
  });
}
