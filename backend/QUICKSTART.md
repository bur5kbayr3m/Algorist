# Quick Start Guide

## 1. Setup Backend (5 minutes)

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python main.py
```

Backend will start on `http://localhost:8000`

## 2. Test Backend (Browser)

Open these URLs in your browser:

1. **API Documentation:** http://localhost:8000/docs
2. **Health Check:** http://localhost:8000/health
3. **Get Market Data:** http://localhost:8000/api/market-data

## 3. Test with Flutter

### Update the backend URL in Flutter:

```dart
// lib/services/backend_api_service.dart
static const String baseUrl = 'http://localhost:8000';  // PC
// OR
static const String baseUrl = 'http://10.0.2.2:8000';   // Android Emulator
```

### Example Flutter usage:

```dart
import 'package:algorist/services/backend_api_service.dart';

final backendService = BackendApiService();

// Test connection
final health = await backendService.checkHealth();
print('Backend status: ${health['status']}');

// Get all market data
final data = await backendService.getAllMarketData();
print('Stocks: ${data['bist100'].length}');
print('Forex: ${data['forex'].length}');
print('Funds: ${data['funds'].length}');
```

## 4. Verify Scheduler is Working

Check logs in terminal where backend is running:

```
2026-01-15 10:00:00 - INFO - ⏰ Scheduled fetch: Group A data
2026-01-15 10:00:05 - INFO - ✅ Updated 45 BIST100 stocks
2026-01-15 10:00:06 - INFO - ✅ Updated 3 forex pairs
2026-01-15 10:00:07 - INFO - ✅ Updated 2 commodities
```

## 5. Manual Refresh (Testing)

Use POST endpoints to trigger immediate fetch:

```bash
# Refresh stocks/forex/commodities (Group A)
curl -X POST http://localhost:8000/api/refresh/stocks

# Refresh funds (Group B)
curl -X POST http://localhost:8000/api/refresh/funds
```

## 6. Check Cached Data Files

Data is persisted in JSON files:

```
backend/data/
├── market_data.json    # Stocks, Forex, Commodities
└── funds_data.json     # TEFAS Funds
```

Open these files to verify data is being cached.

## 7. Monitor Logs

Backend logs show all activities:
- ⏰ Scheduled fetch events
- ✅ Successful data updates
- ❌ Errors (if any)
- 🔄 Manual refresh requests

## Troubleshooting

### Problem: Backend won't start
**Solution:** Check Python version (3.8+), install dependencies

### Problem: No data returned
**Solution:** 
1. Check logs for errors
2. Wait for first scheduled fetch (15 mins max)
3. Use manual refresh endpoint
4. Verify internet connection

### Problem: Flutter can't connect
**Solution:**
1. Check backend is running (`http://localhost:8000/health`)
2. Update `baseUrl` in `backend_api_service.dart`
3. For Android Emulator, use `10.0.2.2` instead of `localhost`
4. For physical device, use PC's local IP (e.g., `192.168.1.100`)

### Problem: TEFAS data empty
**Solution:** 
- TEFAS only updates during market hours (10:00-18:00)
- Check if it's a trading day
- Manual refresh: `POST /api/refresh/funds`

## Production Deployment

### Option 1: Railway (Easiest)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

### Option 2: Heroku
```bash
# Create Procfile
echo "web: python main.py" > Procfile

# Deploy
heroku create algorist-backend
git push heroku main
```

### Option 3: Docker
```dockerfile
# Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "main.py"]
```

```bash
docker build -t algorist-backend .
docker run -p 8000:8000 algorist-backend
```

## Architecture Summary

```
┌─────────────────────────────────────────────────┐
│  Flutter App (Client)                           │
│  ↓ HTTP GET /api/market-data                    │
│  • Instant response (<50ms)                     │
│  • No direct API calls                          │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  FastAPI Backend (Server)                       │
│  • Serves cached data instantly                 │
│  • Thread-safe in-memory cache                  │
│  • JSON persistence on disk                     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  APScheduler (Background Jobs)                  │
│  • Group A: Every 15 min (BIST, Forex, Gold)   │
│  • Group B: 3x daily (TEFAS Funds)              │
│  • Auto-updates cache                           │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  External APIs                                  │
│  • Yahoo Finance (yfinance)                     │
│  • TEFAS (tefas-crawler)                        │
└─────────────────────────────────────────────────┘
```

## Next Steps

1. ✅ Backend running locally
2. ✅ Data fetching automatically
3. 🔄 Update Flutter app to use backend API
4. 🔄 Test on Android Emulator
5. 🔄 Test on physical device
6. 🔄 Deploy backend to production
7. 🔄 Update Flutter app with production URL
8. 🚀 Ship to production!

## Support

For issues, check:
- Backend logs in terminal
- `data/` folder for cached files
- `/health` endpoint for status
- `/docs` for API documentation
