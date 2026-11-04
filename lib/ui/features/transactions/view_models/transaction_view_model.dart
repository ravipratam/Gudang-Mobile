import 'package:flutter/foundation.dart';
import 'package:gudang_mobile/data/models/stock_transaction_model.dart';
import 'package:gudang_mobile/data/repositories/transaction_repository.dart';

class TransactionViewModel extends ChangeNotifier {
  final TransactionRepository _transactionRepo;

  TransactionViewModel({TransactionRepository? transactionRepo})
      : _transactionRepo = transactionRepo ?? TransactionRepository();

  List<StockTransactionModel> _transactions = [];
  List<StockTransactionModel> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _filterType = 'ALL'; // 'ALL', 'IN', 'OUT'
  String get filterType => _filterType;

  void setFilterType(String type) {
    _filterType = type;
    notifyListeners();
  }

  List<StockTransactionModel> get filteredTransactions {
    if (_filterType == 'IN') {
      return _transactions.where((t) => t.isInbound).toList();
    } else if (_filterType == 'OUT') {
      return _transactions.where((t) => t.isOutbound).toList();
    }
    return _transactions;
  }

  Future<void> fetchTransactions({String? productId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _transactionRepo.getTransactions(
        limit: 100,
        productId: productId,
      );
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
