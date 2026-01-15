# Flutter Integration Guide

## How to Migrate from Direct Yahoo Finance to Backend API

### Step 1: Update Dependencies (Already have http package)
```yaml
dependencies:
  http: ^1.2.0  # Already in pubspec.yaml
```

### Step 2: Update Backend URL
In `lib/services/backend_api_service.dart`, update the `baseUrl`:

```dart
// For local testing:
static const String baseUrl = 'http://localhost:8000';

// For Android Emulator:
static const String baseUrl = 'http://10.0.2.2:8000';

// For physical device (same WiFi):
static const String baseUrl = 'http://192.168.1.100:8000';  // Your PC's IP

// For production (deploy backend to cloud):
static const String baseUrl = 'https://your-backend.com';
```

### Step 3: Replace YahooFinanceService Calls

#### BEFORE (Direct Yahoo Finance):
```dart
// In markets_screen.dart or portfolio_screen.dart
import 'package:algorist/services/yahoo_finance_service.dart';

final yahooService = YahooFinanceService();
final stocks = await yahooService.getMultipleQuotes(['THYAO.IS', 'GARAN.IS']);
```

#### AFTER (Backend API):
```dart
// In markets_screen.dart or portfolio_screen.dart
import 'package:algorist/services/backend_api_service.dart';

final backendService = BackendApiService();

// Get all market data at once (fastest)
final marketData = await backendService.getAllMarketData();
final stocks = marketData['bist100'];
final forex = marketData['forex'];
final commodities = marketData['commodities'];
final funds = marketData['funds'];

// OR get specific data only
final stocks = await backendService.getStocks();
final forex = await backendService.getForex();
final funds = await backendService.getFunds();
```

### Step 4: Example Provider Update

Update your existing providers to use the backend:

```dart
// lib/providers/market_provider.dart
import 'package:flutter/foundation.dart';
import 'package:algorist/services/backend_api_service.dart';

class MarketProvider with ChangeNotifier {
  final BackendApiService _backendService = BackendApiService();
  
  List<dynamic> _stocks = [];
  List<dynamic> _forex = [];
  List<dynamic> _funds = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;
  
  // Getters
  List<dynamic> get stocks => _stocks;
  List<dynamic> get forex => _forex;
  List<dynamic> get funds => _funds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  
  /// Fetch all market data from backend
  Future<void> fetchAllMarketData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Single API call gets everything!
      final data = await _backendService.getAllMarketData();
      
      _stocks = data['bist100'] ?? [];
      _forex = data['forex'] ?? [];
      _funds = data['funds'] ?? [];
      _lastUpdate = DateTime.now();
      _error = null;
      
      print('✅ Loaded ${_stocks.length} stocks, ${_forex.length} forex, ${_funds.length} funds');
      
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching market data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Check backend health
  Future<bool> checkBackendHealth() async {
    try {
      final health = await _backendService.checkHealth();
      return health['status'] == 'ok';
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }
}
```

### Step 5: Update Your Screens

#### Example: Markets Screen Update

```dart
// lib/screens/markets_screen.dart

class _MarketsScreenState extends State<MarketsScreen> {
  final BackendApiService _backendService = BackendApiService();
  List<dynamic> _marketData = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }
  
  Future<void> _loadMarketData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _backendService.getAllMarketData();
      setState(() {
        // Combine all data
        _marketData = [
          ...data['bist100'] ?? [],
          ...data['forex'] ?? [],
          ...data['commodities'] ?? [],
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => _isLoading = false);
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend bağlantı hatası: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Piyasalar')),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadMarketData,
            child: ListView.builder(
              itemCount: _marketData.length,
              itemBuilder: (context, index) {
                final item = _marketData[index];
                return ListTile(
                  title: Text(item['name'] ?? item['symbol']),
                  subtitle: Text('${item['price']}'),
                  trailing: Text(
                    '${item['change_percent']}%',
                    style: TextStyle(
                      color: item['change_percent'] >= 0 
                        ? Colors.green 
                        : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }
}
```

### Step 6: Performance Benefits

**BEFORE (Direct Yahoo Finance):**
- ❌ Each API call takes 2-5 seconds
- ❌ Rate limiting issues
- ❌ Network delays
- ❌ Battery drain from frequent requests

**AFTER (Backend API):**
- ✅ API response < 50ms (cached data)
- ✅ No rate limiting
- ✅ Automatic 15-min updates in background
- ✅ Single source of truth
- ✅ Reduced battery usage

### Step 7: Testing Backend Connection

Add a debug screen to test the connection:

```dart
// Test if backend is reachable
final backendService = BackendApiService();

try {
  final health = await backendService.checkHealth();
  print('✅ Backend is healthy: $health');
  
  final data = await backendService.getAllMarketData();
  print('✅ Got ${data['bist100'].length} stocks');
} catch (e) {
  print('❌ Backend error: $e');
  // Fallback to old YahooFinanceService if needed
}
```

### Step 8: Deployment Considerations

1. **Local Development:** Run backend on `localhost:8000`
2. **Testing on Device:** Use your PC's local IP (e.g., `192.168.1.100:8000`)
3. **Production:** Deploy backend to:
   - Railway.app (easy Python deployment)
   - Heroku
   - DigitalOcean
   - AWS/GCP
   - Then update `baseUrl` to your production URL

### Step 9: Backward Compatibility

Keep `YahooFinanceService` as fallback:

```dart
Future<List<dynamic>> getStocksWithFallback() async {
  try {
    // Try backend first
    return await backendService.getStocks();
  } catch (e) {
    print('Backend unavailable, using fallback');
    // Fallback to direct Yahoo Finance
    return await yahooFinanceService.getMultipleQuotes(symbols);
  }
}
```

## Summary

✅ Backend handles all data fetching automatically  
✅ Flutter app just reads cached data (instant response)  
✅ No more rate limiting or slow API calls  
✅ Automatic background updates every 15 minutes  
✅ TEFAS funds updated 3x daily  
✅ Reduced battery usage on mobile devices  
✅ Single source of truth for all market data  
