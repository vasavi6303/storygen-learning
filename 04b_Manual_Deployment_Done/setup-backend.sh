#!/bin/bash
# StoryGen Backend Setup Script
echo "🚀 Setting up StoryGen Backend..."

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed. Please install Python 3.8+ first."
    exit 1
fi

# Navigate to backend directory
cd backend

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source .venv/bin/activate

# Upgrade pip
echo "⬆️ Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "📥 Installing dependencies from requirements.txt..."
pip install -r requirements.txt

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚙️ Creating .env file from template..."
    cp env.example .env
    echo ""
    echo "🔑 IMPORTANT: Your .env file has been created in the 'backend' directory."
    echo "   Please edit it now and add your Google Cloud credentials."
else
    echo "✅ .env file already exists."
fi

echo ""
echo "🎉 Backend setup complete!"
echo ""
echo "Next step: Start the backend server with the following commands:"
echo "   cd backend"
echo "   source .venv/bin/activate"
echo "   python main.py"
echo ""
