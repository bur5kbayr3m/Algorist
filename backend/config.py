import os
from typing import List

class Settings:
    """Application configuration"""
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True
    
    # Paths
    BASE_DIR: str = os.path.dirname(os.path.abspath(__file__))
    DATA_DIR: str = os.path.join(BASE_DIR, "data")
    
    # Cache files
    MARKET_DATA_FILE: str = os.path.join(DATA_DIR, "market_data.json")
    FUNDS_DATA_FILE: str = os.path.join(DATA_DIR, "funds_data.json")
    
    # Scheduler intervals
    HIGH_FREQ_INTERVAL_MINUTES: int = 15  # Full cycle: Every 15 minutes
    STOCK_GROUP_INTERVAL_MINUTES: int = 3  # Each group: Every 3 minutes
    FUND_FETCH_TIMES: List[str] = ["10:00", "14:00", "18:00"]  # Group B: 3x daily
    
    # BIST100 Stock Symbols - ALL 100 stocks split into 5 groups (20 each)
    # Each group fetched every 3 minutes to avoid rate limiting
    # Cycle: 0min → 3min → 6min → 9min → 12min → repeats at 15min
    
    BIST100_GROUP_1: List[str] = [
        "THYAO.IS", "GARAN.IS", "AKBNK.IS", "YKBNK.IS", "SAHOL.IS",
        "EREGL.IS", "KCHOL.IS", "TUPRS.IS", "SISE.IS", "ASELS.IS",
        "PETKM.IS", "KOZAL.IS", "PGSUS.IS", "TTKOM.IS", "ISCTR.IS",
        "VESTL.IS", "BIMAS.IS", "ENKAI.IS", "TAVHL.IS", "TCELL.IS"
    ]
    
    BIST100_GROUP_2: List[str] = [
        "EKGYO.IS", "KOZAA.IS", "SASA.IS", "TOASO.IS", "DOHOL.IS",
        "FROTO.IS", "HALKB.IS", "VAKBN.IS", "ARCLK.IS", "ODAS.IS",
        "KRDMD.IS", "SODA.IS", "GUBRF.IS", "AEFES.IS", "MGROS.IS",
        "SOKM.IS", "ENJSA.IS", "ALARK.IS", "TTRAK.IS", "AKSA.IS"
    ]
    
    BIST100_GROUP_3: List[str] = [
        "AYGAZ.IS", "OYAKC.IS", "ULKER.IS", "MAVI.IS", "BRSAN.IS",
        "CIMSA.IS", "CCOLA.IS", "DOAS.IS", "GLYHO.IS", "GOODY.IS",
        "IHLAS.IS", "KARSN.IS", "KLMSN.IS", "KONTR.IS", "KUTPO.IS",
        "MPARK.IS", "NTHOL.IS", "OTKAR.IS", "PARSN.IS", "GARAN.IS"
    ]
    
    BIST100_GROUP_4: List[str] = [
        "PRKME.IS", "SELEC.IS", "SNGYO.IS", "TATGD.IS", "TBORG.IS",
        "TKNSA.IS", "TMSN.IS", "TRKCM.IS", "TSKB.IS", "TURSG.IS",
        "VAKKO.IS", "VESBE.IS", "YATAS.IS", "ZOREN.IS", "BJKAS.IS",
        "CRFSA.IS", "DZGYO.IS", "EGEEN.IS", "GENIL.IS", "GENTS.IS"
    ]
    
    BIST100_GROUP_5: List[str] = [
        "IHLGM.IS", "INDES.IS", "ISMEN.IS", "IZMDC.IS", "KERVT.IS",
        "KLKIM.IS", "KORDS.IS", "KONYA.IS", "LOGO.IS", "MAKTK.IS",
        "MERCN.IS", "NUGYO.IS", "PINSU.IS", "REEDR.IS", "RYGYO.IS",
        "SKBNK.IS", "SRVGY.IS", "TRGYO.IS", "TRILC.IS", "PGSUS.IS"
    ]
    
    # All groups combined (100 stocks total)
    BIST100_SYMBOLS: List[str] = (
        BIST100_GROUP_1 + BIST100_GROUP_2 + BIST100_GROUP_3 + 
        BIST100_GROUP_4 + BIST100_GROUP_5
    )
    
    # Forex pairs
    FOREX_SYMBOLS: List[str] = [
        "TRY=X",      # USD/TRY
        "EURTRY=X",   # EUR/TRY
        "GBPTRY=X"    # GBP/TRY
    ]
    
    # Commodities
    COMMODITY_SYMBOLS: List[str] = [
        "GC=F",  # Gold Futures
        "SI=F"   # Silver Futures
    ]
    
    # API Settings
    CORS_ORIGINS: List[str] = ["*"]  # In production, specify your Flutter app's origin
    
    # Logging
    LOG_LEVEL: str = "INFO"

settings = Settings()

# Ensure data directory exists
os.makedirs(settings.DATA_DIR, exist_ok=True)
