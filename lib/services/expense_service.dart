import 'dart:io';
import 'dart:isolate';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';

/// Service class for handling expense-related file operations and data processing
class ExpenseService {
  /// Required CSV columns for expense data (ID column is optional)
  static const List<String> _requiredColumns = [
    'date',
    'description', 
    'amount',
    'type',
    'account_number',
    'currency'
  ];

  // ========================================
  // FILE PICKING METHODS
  // ========================================

  /// Picks a CSV file and returns its path (for non-web platforms)
  static Future<String?> pickCsvFile() async {
    try {
      final result = await _pickFile();
      return result?.files.single.path;
    } catch (e) {
      throw Exception('Error picking file: $e');
    }
  }

  /// Picks and parses a CSV file directly (recommended for web compatibility)
  static Future<List<Expense>> pickAndParseCsvFile() async {
    try {
      final result = await _pickFile(withData: true);

      if (result?.files.isNotEmpty != true) {
        throw Exception('No file selected');
      }

      final file = result!.files.single;
      if (file.bytes == null) {
        throw Exception('Could not read file content');
      }

      final content = String.fromCharCodes(file.bytes!);
      return await _parseCSVContentAsync(content);
    } catch (e) {
      throw Exception('Error picking and parsing file: $e');
    }
  }

  /// Internal helper method for file picking
  static Future<FilePickerResult?> _pickFile({bool withData = false}) async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
      withData: withData,
    );
  }

  // ========================================
  // CSV PARSING METHODS
  // ========================================

  /// Parses a CSV file from file path (for non-web platforms)
  static Future<List<Expense>> parseCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      return await _parseCSVContentAsync(content);
    } catch (e) {
      throw Exception('Error parsing CSV file: $e');
    }
  }

  /// Parses CSV content string into list of expenses (async to prevent UI blocking)
  static Future<List<Expense>> _parseCSVContentAsync(String content) async {
    try {
      // Parse CSV data first to get row count
      final csvData = const CsvToListConverter().convert(content);
      
      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // For very large files (>50KB) or many rows (>1000), use isolate
      if (content.length > 50000 || csvData.length > 1000) {
        return await compute(_parseCSVContentIsolate, content);
      } else {
        // Use async processing for better responsiveness even with smaller files
        return await _processCSVDataAsync(csvData);
      }
    } catch (e) {
      throw Exception('Error parsing CSV content: $e');
    }
  }

  /// Static function for isolate parsing (must be top-level or static)
  static List<Expense> _parseCSVContentIsolate(String content) {
    return _parseCSVContent(content);
  }

  /// Parses CSV content string into list of expenses (synchronous version)
  static List<Expense> _parseCSVContent(String content) {
    try {
      final csvData = const CsvToListConverter().convert(content);
      
      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      return _processCSVData(csvData);
    } catch (e) {
      throw Exception('Error parsing CSV content: $e');
    }
  }

  /// Processes parsed CSV data into expense objects
  static List<Expense> _processCSVData(List<List<dynamic>> csvData) {
    // Get header row and create column mapping
    final headerRow = csvData[0].map((cell) => cell.toString()).toList();
    final columnIndices = Expense.createColumnMapping(headerRow);
    
    // Validate required columns exist
    _validateRequiredColumns(columnIndices);
    
    // Parse data rows (skip header row)
    return _parseDataRows(csvData.skip(1).toList(), columnIndices);
  }

  /// Processes parsed CSV data into expense objects (async version for large files)
  static Future<List<Expense>> _processCSVDataAsync(List<List<dynamic>> csvData) async {
    // Get header row and create column mapping
    final headerRow = csvData[0].map((cell) => cell.toString()).toList();
    final columnIndices = Expense.createColumnMapping(headerRow);
    
    // Validate required columns exist
    _validateRequiredColumns(columnIndices);
    
    // Parse data rows (skip header row)
    final dataRows = csvData.skip(1).toList();
    
    // Use async parsing for datasets with more than 50 rows to prevent UI blocking
    if (dataRows.length > 50) {
      return await _parseDataRowsAsync(dataRows, columnIndices);
    } else {
      // For very small files, add a small delay and process synchronously
      await Future.delayed(const Duration(milliseconds: 10));
      return _parseDataRows(dataRows, columnIndices);
    }
  }

  /// Validates that all required columns are present in the CSV
  static void _validateRequiredColumns(Map<String, int> columnIndices) {
    final missingColumns = <String>[];
    
    for (final column in _requiredColumns) {
      if (!_columnExists(column, columnIndices)) {
        missingColumns.add(column);
      }
    }
    
    if (missingColumns.isNotEmpty) {
      throw Exception(
        'Missing required columns: ${missingColumns.join(', ')}. '
        'Available columns: ${columnIndices.keys.join(', ')}'
      );
    }
  }

  /// Checks if a column exists, including common variations
  static bool _columnExists(String column, Map<String, int> columnIndices) {
    // Check for exact match first
    if (columnIndices.containsKey(column)) return true;
    
    // Check for common column name variations
    switch (column) {
      case 'currency':
        return columnIndices.containsKey('curr') ||
               columnIndices.containsKey('curren') ||
               columnIndices.containsKey('currencies');
      case 'account_number':
        return columnIndices.containsKey('account number') ||
               columnIndices.containsKey('accountnumber') ||
               columnIndices.containsKey('account_no') ||
               columnIndices.containsKey('acc_number');
      default:
        return false;
    }
  }

  /// Parses individual data rows into Expense objects
  static List<Expense> _parseDataRows(
    List<List<dynamic>> dataRows, 
    Map<String, int> columnIndices
  ) {
    final expenses = <Expense>[];
    final expectedColumns = columnIndices.values.reduce((a, b) => a > b ? a : b) + 1;
    
    for (final row in dataRows) {
      if (row.isEmpty) continue; // Skip empty rows
      
      final stringRow = row.map((cell) => cell.toString()).toList();
      
      // Validate row has enough columns
      if (stringRow.length < expectedColumns) {
        throw Exception(
          'Row has ${stringRow.length} columns but expected $expectedColumns. '
          'Row: ${stringRow.join(", ")}'
        );
      }
      
      expenses.add(Expense.fromCsvRow(stringRow, columnIndices));
    }
    
    return expenses;
  }

  /// Parses data rows in batches to prevent UI blocking (for very large files)
  static Future<List<Expense>> _parseDataRowsAsync(
    List<List<dynamic>> dataRows,
    Map<String, int> columnIndices,
  ) async {
    final expenses = <Expense>[];
    final expectedColumns = columnIndices.values.reduce((a, b) => a > b ? a : b) + 1;
    
    // Adjust batch size based on total rows
    final batchSize = dataRows.length > 1000 ? 50 : 25; // Smaller batches for better responsiveness
    
    for (int i = 0; i < dataRows.length; i += batchSize) {
      final batch = dataRows.skip(i).take(batchSize);
      
      for (final row in batch) {
        if (row.isEmpty) continue; // Skip empty rows
        
        final stringRow = row.map((cell) => cell.toString()).toList();
        
        // Validate row has enough columns
        if (stringRow.length < expectedColumns) {
          throw Exception(
            'Row has ${stringRow.length} columns but expected $expectedColumns. '
            'Row: ${stringRow.join(", ")}'
          );
        }
        
        expenses.add(Expense.fromCsvRow(stringRow, columnIndices));
      }
      
      // Yield control back to the event loop every batch for UI responsiveness
      await Future.delayed(const Duration(milliseconds: 5));
    }
    
    return expenses;
  }

  // ========================================
  // DATA ANALYSIS METHODS
  // ========================================

  /// Returns expenses grouped by month for the last three months
  static List<MonthlyExpense> getLastThreeMonthsExpenses(List<Expense> expenses) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
    
    // Filter expenses from the last three months
    final filteredExpenses = expenses.where((expense) {
      return expense.date.isAfter(threeMonthsAgo.subtract(const Duration(days: 1))) &&
             expense.date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    return _groupExpensesByMonth(filteredExpenses);
  }

  /// Groups expenses by month and calculates totals
  static List<MonthlyExpense> _groupExpensesByMonth(List<Expense> expenses) {
    final groupedByMonth = <String, List<Expense>>{};
    
    // Group expenses by year-month key
    for (final expense in expenses) {
      final monthKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      groupedByMonth.putIfAbsent(monthKey, () => <Expense>[]).add(expense);
    }

    // Create MonthlyExpense objects
    final monthlyExpenses = <MonthlyExpense>[];
    for (final entry in groupedByMonth.entries) {
      final monthDate = DateTime.parse('${entry.key}-01');
      final totalAmount = entry.value.fold<double>(
        0.0, 
        (sum, expense) => sum + expense.amount
      );
      
      monthlyExpenses.add(MonthlyExpense(
        month: monthDate,
        totalAmount: totalAmount,
        expenses: entry.value,
      ));
    }

    // Sort by month chronologically
    monthlyExpenses.sort((a, b) => a.month.compareTo(b.month));
    return monthlyExpenses;
  }

  /// Returns expense breakdown by category/type
  static Map<String, double> getCategoryBreakdown(List<Expense> expenses) {
    final categoryTotals = <String, double>{};
    
    for (final expense in expenses) {
      // Only include actual expenses (debits - negative amounts)
      if (expense.amount < 0) {
        String category = categorizeExpense(expense.description);
        double expenseAmount = expense.amount.abs(); // Convert to positive
        
        categoryTotals.update(
          category,
          (value) => value + expenseAmount,
          ifAbsent: () => expenseAmount,
        );
      }
    }
    
    return categoryTotals;
  }

  /// Categorizes expenses based on merchant/description
  static String categorizeExpense(String description) {
    final desc = description.toUpperCase();
    
    // Food & Dining
    if (desc.contains('MCDONALD') || 
        desc.contains('DOMINO') || 
        desc.contains('DPZ') ||
        desc.contains('STARBUCKS') ||
        desc.contains('LOCAL DELI') ||
        desc.contains('LIDL')) {
      return 'Food & Dining';
    }
    
    // Entertainment
    if (desc.contains('NETFLIX') || 
        desc.contains('SPOTIFY') ||
        desc.contains('CINEMA') ||
        desc.contains('CONCERT') ||
        desc.contains('TKT*CONCERT') ||
        desc.contains('GAMESTORE') ||
        desc.contains('TKT*GAMESTORE')) {
      return 'Entertainment';
    }
    
    // Shopping
    if (desc.contains('AMAZON') || 
        desc.contains('AMZN') ||
        desc.contains('ZARA') ||
        desc.contains('BOOKSTORE') ||
        desc.contains('TECH STORE') ||
        desc.contains('TKT*BOOKSTORE')) {
      return 'Shopping';
    }
    
    // Transportation & Parking
    if (desc.contains('PARKING') || 
        desc.contains('TKT*PARKINGGAR') ||
        desc.contains('PUBLICPARKIN')) {
      return 'Transportation';
    }
    
    // Bills & Utilities
    if (desc.contains('MONTHLYREN') || 
        desc.contains('TKT*MONTHLYREN')) {
      return 'Rent & Bills';
    }
    
    // Transfers & Fees
    if (desc.contains('REVOLUT') || 
        desc.contains('P2P') ||
        desc.contains('FX FEE') ||
        desc.contains('CONV TO EUR') ||
        desc.contains('MALTA POST')) {
      return 'Transfers & Fees';
    }
    
    // Google Services (could be various things)
    if (desc.contains('GOOGLE')) {
      return 'Digital Services';
    }
    
    // Default category for unmatched descriptions
    return 'Other';
  }
}
