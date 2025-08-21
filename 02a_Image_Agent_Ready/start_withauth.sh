#!/bin/bash
# ====================================================
# Combined Story Generation App Startup Script
#
# This script:
# 1. Activates the virtual environment
# 2. Configures gcloud authentication and project settings
# 3. Builds the frontend
# 4. Starts the backend server
#
# Usage:
#   ./startup.sh [PROJECT_ID]
# ====================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the script directory and navigate to it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Function to setup virtual environment ---
setup_virtual_env() {
    echo -e "${BLUE}📦 Setting up virtual environment...${NC}"
    
    if [ -f "../.venv/bin/activate" ]; then
        source ../.venv/bin/activate
        echo -e "${GREEN}✅ Virtual environment activated${NC}"
    elif [ -f "../../.venv/bin/activate" ]; then
        # Try two levels up (in case we're in a subdirectory)
        source ../../.venv/bin/activate
        echo -e "${GREEN}✅ Virtual environment activated (found at ../../.venv)${NC}"
    else
        echo -e "${YELLOW}⚠️  Virtual environment not found. Setting up now...${NC}"
        echo -e "${BLUE}📋 Running shared virtual environment setup...${NC}"
        
        # Navigate to setup directory and run the setup script
        if [ -f "../00_Starting_Here/setup-shared-venv.sh" ]; then
            cd ../00_Starting_Here
            ./setup-shared-venv.sh
            cd "$SCRIPT_DIR"
            source ../.venv/bin/activate
            echo -e "${GREEN}✅ Virtual environment created and activated${NC}"
        else
            echo -e "${RED}❌ Setup script not found. Please run:${NC}"
            echo "  cd ../00_Starting_Here && ./setup-shared-venv.sh"
            echo "  Or manually create: cd .. && python -m venv .venv"
            exit 1
        fi
    fi
}

# --- Function to check prerequisites ---
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check for gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}❌ gcloud CLI not found. Please install it to continue.${NC}"
        echo "   Follow instructions at: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    echo -e "${GREEN}✅ gcloud CLI is installed.${NC}"

    # Check for npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm not found. Please install Node.js and npm.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ npm is installed.${NC}"

    # Check for python
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python not found. Please install Python.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Python is installed.${NC}"

    # Check if user is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "."; then
        echo -e "${YELLOW}⚠️ You are not logged into gcloud.${NC}"
        echo -e "${BLUE}Please log in with your Google account...${NC}"
        gcloud auth login
        gcloud auth application-default login
    fi
    
    local current_account=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1)
    echo -e "${GREEN}✅ Authenticated as: ${current_account}${NC}"
}

# --- Function to get project configuration ---
get_project_config() {
    if [ -n "$1" ]; then
        PROJECT_ID="$1"
        echo -e "${GREEN}✅ Using Project ID from argument: $PROJECT_ID${NC}"
    else
        local current_project
        current_project=$(gcloud config get-value project 2>/dev/null)
        
        if [ -n "$current_project" ]; then
            read -p "$(echo -e "${YELLOW}❓ Project ID is currently set to '$current_project'. Use this one? (Y/n): ${NC}")" -r use_current
            if [[ $use_current =~ ^[Nn]$ ]]; then
                 read -p "$(echo -e "${BLUE}Enter your Google Cloud Project ID: ${NC}")" -r PROJECT_ID
            else
                PROJECT_ID=$current_project
            fi
        else
            read -p "$(echo -e "${BLUE}Enter your Google Cloud Project ID: ${NC}")" -r PROJECT_ID
        fi
    fi

    if [ -z "$PROJECT_ID" ]; then
        echo -e "${RED}❌ No Project ID provided. Exiting.${NC}"
        exit 1
    fi
    
    if ! gcloud projects describe "$PROJECT_ID" > /dev/null 2>&1; then
        echo -e "${RED}❌ Project '$PROJECT_ID' not found or you don't have access.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Project '$PROJECT_ID' is valid and accessible.${NC}"
}

# --- Function to configure authentication ---
configure_auth() {
    echo -e "${BLUE}🔧 Configuring gcloud project...${NC}"
    gcloud config set project "$PROJECT_ID"
    echo -e "${GREEN}✅ gcloud project set to '$PROJECT_ID'.${NC}"
    
    echo -e "${BLUE}🔧 Setting quota project for Application Default Credentials...${NC}"
    gcloud auth application-default set-quota-project "$PROJECT_ID"
    echo -e "${GREEN}✅ Quota project set to '$PROJECT_ID'.${NC}"
    
    echo -e "${GREEN}🎉 Authentication and project configuration complete!${NC}"
}

# --- Function to setup frontend ---
setup_frontend() {
    echo -e "${BLUE}🎨 Setting up frontend...${NC}"
    
    # Check if frontend directory exists
    if [ ! -d "frontend" ]; then
        echo -e "${RED}❌ frontend directory not found${NC}"
        exit 1
    fi
    
    cd frontend

    # Install dependencies
    echo -e "${BLUE}📥 Installing npm dependencies...${NC}"
    npm install

    # Build the frontend
    echo -e "${BLUE}🏗️  Building frontend...${NC}"
    npm run build

    echo -e "${GREEN}✅ Frontend build completed${NC}"
    
    # Return to script directory
    cd "$SCRIPT_DIR"
}

# --- Function to start backend ---
start_backend() {
    echo -e "${BLUE}🔧 Starting backend server...${NC}"
    
    # Check if backend directory exists
    if [ ! -d "backend" ]; then
        echo -e "${RED}❌ backend directory not found${NC}"
        exit 1
    fi
    
    cd backend

    # Check if main.py exists
    if [ ! -f "main.py" ]; then
        echo -e "${RED}❌ main.py not found in backend directory${NC}"
        exit 1
    fi

    echo -e "${GREEN}🌟 Starting Python backend server...${NC}"
    echo -e "${BLUE}Backend will be running at: http://localhost:8000${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
    echo "----------------------------------------"

    # Start the backend server
    python main.py
}

# --- Main execution ---
main() {
    echo -e "${BLUE}🚀 Starting Story Generation App Complete Setup...${NC}"
    echo ""
    
    # Step 1: Setup virtual environment
    setup_virtual_env
    echo ""
    
    # Step 2: Check prerequisites and authentication
    check_prerequisites
    echo ""
    
    # Step 3: Configure project
    get_project_config "$@"
    echo ""
    
    # Step 4: Configure authentication
    configure_auth
    echo ""
    
    # Step 5: Setup frontend
    setup_frontend
    echo ""
    
    # Step 6: Start backend
    start_backend
}

main "$@"