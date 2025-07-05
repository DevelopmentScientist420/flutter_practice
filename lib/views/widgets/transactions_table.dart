import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';

class TransactionsTable extends StatefulWidget {
  final List<Expense> expenses;

  const TransactionsTable({
    super.key,
    required this.expenses,
  });

  @override
  State<TransactionsTable> createState() => _TransactionsTableState();
}

class _TransactionsTableState extends State<TransactionsTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = false;
  List<Expense> _sortedExpenses = [];
  
  // Pagination variables
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  late int _totalPages;

  @override
  void initState() {
    super.initState();
    _sortedExpenses = List.from(widget.expenses);
    _calculateTotalPages();
    _sortExpenses();
  }

  @override
  void didUpdateWidget(TransactionsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expenses != oldWidget.expenses) {
      _sortedExpenses = List.from(widget.expenses);
      _currentPage = 0; // Reset to first page when data changes
      _calculateTotalPages();
      _sortExpenses();
    }
  }

  void _calculateTotalPages() {
    _totalPages = (_sortedExpenses.length / _rowsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;
  }

  void _sortExpenses() {
    _sortedExpenses.sort((a, b) {
      int result;
      switch (_sortColumnIndex) {
        case 0: // Date
          result = a.date.compareTo(b.date);
          break;
        case 1: // Description
          result = a.description.compareTo(b.description);
          break;
        case 2: // Amount
          result = a.amount.compareTo(b.amount);
          break;
        case 3: // Type
          result = a.type.compareTo(b.type);
          break;
        default:
          result = 0;
      }
      return _sortAscending ? result : -result;
    });
    _calculateTotalPages();
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortExpenses();
    });
  }

  List<Expense> _getCurrentPageExpenses() {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _sortedExpenses.length);
    return _sortedExpenses.sublist(startIndex, endIndex);
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page.clamp(0, _totalPages - 1);
    });
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Page info
        Text(
          'Page ${_currentPage + 1} of $_totalPages',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        // Pagination buttons
        Row(
          children: [
            // First page
            IconButton(
              onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
              icon: const Icon(Icons.first_page),
              tooltip: 'First Page',
            ),
            
            // Previous page
            IconButton(
              onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Page',
            ),
            
            // Page numbers (show current and adjacent pages)
            ..._buildPageNumbers(),
            
            // Next page
            IconButton(
              onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Page',
            ),
            
            // Last page
            IconButton(
              onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_totalPages - 1) : null,
              icon: const Icon(Icons.last_page),
              tooltip: 'Last Page',
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];
    int startPage = (_currentPage - 2).clamp(0, _totalPages - 1);
    int endPage = (_currentPage + 2).clamp(0, _totalPages - 1);
    
    // Ensure we show at least 5 pages if available
    if (endPage - startPage < 4) {
      if (startPage == 0) {
        endPage = (startPage + 4).clamp(0, _totalPages - 1);
      } else if (endPage == _totalPages - 1) {
        startPage = (endPage - 4).clamp(0, _totalPages - 1);
      }
    }
    
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: TextButton(
            onPressed: () => _goToPage(i),
            style: TextButton.styleFrom(
              backgroundColor: i == _currentPage ? Colors.cyan : null,
              foregroundColor: i == _currentPage ? Colors.white : Colors.cyan,
              minimumSize: const Size(40, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text('${i + 1}'),
          ),
        ),
      );
    }
    
    return pageNumbers;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.expenses.isEmpty) {
      return Card(
        elevation: 4,
        margin: const EdgeInsets.all(0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No transactions available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final currentPageExpenses = _getCurrentPageExpenses();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.expenses.length} transactions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 200, // Account for reduced card padding
                  ),
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columnSpacing: 8,
                    headingRowHeight: 36,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 44,
                    columns: [
                      DataColumn(
                        label: const Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text(
                          'Amount',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn(
                        label: const Text(
                          'Type',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onSort: _onSort,
                      ),
                    ],
                    rows: currentPageExpenses.map((expense) {
                      bool isExpense = expense.amount < 0;
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              dateFormat.format(expense.date),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Text(
                                expense.description,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              '€${expense.amount.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isExpense 
                                    ? Colors.red.withValues(alpha: .1)
                                    : Colors.green.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isExpense 
                                      ? Colors.red.withValues(alpha: .3)
                                      : Colors.green.withValues(alpha: .3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isExpense ? 'Expense' : 'Income',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isExpense ? Colors.red[700] : Colors.green[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Pagination Controls
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }
}
