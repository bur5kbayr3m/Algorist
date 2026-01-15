# ========================================
# CLEAN REINSTALL COMMANDS
# ========================================
#
# Execute these commands in PowerShell terminal:

# 1. Navigate to backend directory
cd backend

# 2. Activate virtual environment
.\venv\Scripts\Activate.ps1

# 3. Upgrade pip to latest version
python -m pip install --upgrade pip

# 4. Uninstall all packages (clean slate)
pip freeze > temp_packages.txt
pip uninstall -r temp_packages.txt -y
Remove-Item temp_packages.txt

# 5. Install from requirements.txt
pip install -r requirements.txt

# 6. Verify installation
pip list

# 7. Test Python imports
python -c "import yfinance; import fastapi; import requests; print('✅ All imports successful')"

# ========================================
# VS CODE PYTHON INTERPRETER FIX
# ========================================
#
# 1. Press: Ctrl+Shift+P
# 2. Type: Python: Select Interpreter
# 3. Choose: .\backend\venv\Scripts\python.exe
# 4. Reload VS Code: Ctrl+Shift+P → "Developer: Reload Window"
#
# ========================================
# VERIFY CIRCUIT BREAKER TEST
# ========================================
#
# Test the new service:
cd backend
.\venv\Scripts\Activate.ps1
python -c "from services.yahoo_service_professional import yahoo_service; print('✅ Circuit breaker loaded')"
