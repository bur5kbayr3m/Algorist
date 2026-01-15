# Algorist Backend - Financial Data Service

## Architecture Overview
This backend serves as a centralized data-fetching service for the Algorist Flutter application.

## Project Structure
```
backend/
├── main.py                 # FastAPI application entry point
├── scheduler.py            # APScheduler configuration
├── services/
│   ├── __init__.py
│   ├── yahoo_service.py    # BIST100, Forex, Commodities (Group A)
│   └── tefas_service.py    # Turkish Investment Funds (Group B)
├── cache/
│   ├── __init__.py
│   └── cache_manager.py    # In-memory + JSON persistence
├── models/
│   ├── __init__.py
│   └── schemas.py          # Pydantic models
├── config.py               # Configuration settings
├── requirements.txt        # Python dependencies
└── data/                   # JSON cache storage
    ├── market_data.json
    └── funds_data.json
```

## Installation

```bash
# Create virtual environment
python -m venv venv
venv\Scripts\activate  # Windows
# source venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt

# Run the server
python main.py
```

## API Endpoints

### Get All Market Data
```
GET /api/market-data
Response: {
  "bist100": [...],
  "forex": [...],
  "commodities": [...],
  "funds": [...],
  "last_updated": {
    "stocks": "2026-01-15T10:30:00",
    "funds": "2026-01-15T10:00:00"
  }
}
```

### Health Check
```
GET /health
Response: {"status": "ok", "scheduler": "running"}
```

## Scheduling Rules

**Group A (Every 15 minutes):**
- BIST100 Stocks
- Forex (TRY=X, EURTRY=X, GBPTRY=X)
- Commodities (GC=F, SI=F)

**Group B (3x daily at 10:00, 14:00, 18:00):**
- All TEFAS funds

## Flutter Integration

Update your Flutter service to call:
```dart
final response = await http.get('http://localhost:8000/api/market-data');
```
