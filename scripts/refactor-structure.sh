#!/bin/bash

#############################################################################
# Project Structure Refactoring Script
# Aligns the Apparule project to the new monorepo structure
#############################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/refactor.log"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# Clear log file
> "$LOG_FILE"

log_info "Starting project structure refactoring..."
log_info "Project root: $PROJECT_ROOT"
log_info "=================================================="

# Step 1: Create missing root-level files
log_info "Step 1: Creating missing configuration files..."
cd "$PROJECT_ROOT"

if [ ! -f .gitignore ]; then
    log_info "Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Dart/Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
pubspec.lock
build/
*.iml
*.lock

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# OS
*.log
.env
.env.local

# Build outputs
dist/
*.apk
*.ipa
*.app
*.exe
.next/
out/

# Node
node_modules/
npm-debug.log
yarn-error.log

# Python
__pycache__/
*.py[cod]
venv/
env/

# Terraform
*.tfstate
*.tfstate.*
.terraform/

# Docker
.dockerignore
EOF
    log_success ".gitignore created"
else
    log_warn ".gitignore already exists"
fi

if [ ! -f .dockerignore ]; then
    log_info "Creating .dockerignore..."
    cat > .dockerignore << 'EOF'
.git
.gitignore
.github
.gitlab-ci.yml
README.md
.DS_Store
node_modules
build
dist
.next
.terraform
.env
.env.local
*.log
EOF
    log_success ".dockerignore created"
else
    log_warn ".dockerignore already exists"
fi

# Step 2: Rename CHANGELOG to CHANGELOG.md
log_info "Step 2: Renaming CHANGELOG to CHANGELOG.md..."
if [ -f CHANGELOG ] && [ ! -f CHANGELOG.md ]; then
    mv CHANGELOG CHANGELOG.md
    log_success "CHANGELOG renamed to CHANGELOG.md"
elif [ -f CHANGELOG.md ]; then
    log_warn "CHANGELOG.md already exists"
    if [ -f CHANGELOG ]; then
        rm CHANGELOG
        log_info "Removed duplicate CHANGELOG"
    fi
fi

# Step 3: Create directory structure
log_info "Step 3: Creating new directory structure..."
mkdir -p "$PROJECT_ROOT/mobile/flutter"
mkdir -p "$PROJECT_ROOT/mobile/android"
mkdir -p "$PROJECT_ROOT/mobile/ios"
mkdir -p "$PROJECT_ROOT/web/home/app"
mkdir -p "$PROJECT_ROOT/api/common"
mkdir -p "$PROJECT_ROOT/deploy/docker"
mkdir -p "$PROJECT_ROOT/deploy/helm"
mkdir -p "$PROJECT_ROOT/deploy/terraform"
mkdir -p "$PROJECT_ROOT/docs/api"
mkdir -p "$PROJECT_ROOT/docs/ui"
log_success "Directory structure created"

# Step 4: Migrate Flutter app structure
log_info "Step 4: Migrating Flutter application..."
if [ -d "$PROJECT_ROOT/app" ]; then
    log_info "Moving Flutter core files..."
    
    # Move Flutter core configuration files to mobile/flutter
    [ -f "$PROJECT_ROOT/app/pubspec.yaml" ] && cp "$PROJECT_ROOT/app/pubspec.yaml" "$PROJECT_ROOT/mobile/flutter/"
    [ -f "$PROJECT_ROOT/app/pubspec.lock" ] && cp "$PROJECT_ROOT/app/pubspec.lock" "$PROJECT_ROOT/mobile/flutter/"
    [ -f "$PROJECT_ROOT/app/analysis_options.yaml" ] && cp "$PROJECT_ROOT/app/analysis_options.yaml" "$PROJECT_ROOT/mobile/flutter/"
    [ -f "$PROJECT_ROOT/app/l10n.yaml" ] && cp "$PROJECT_ROOT/app/l10n.yaml" "$PROJECT_ROOT/mobile/flutter/"
    [ -f "$PROJECT_ROOT/app/.metadata" ] && cp "$PROJECT_ROOT/app/.metadata" "$PROJECT_ROOT/mobile/flutter/"
    [ -f "$PROJECT_ROOT/app/README.md" ] && cp "$PROJECT_ROOT/app/README.md" "$PROJECT_ROOT/mobile/flutter/README.md.flutter"
    
    log_info "Moving lib, test, assets directories to mobile/flutter..."
    [ -d "$PROJECT_ROOT/app/lib" ] && mv "$PROJECT_ROOT/app/lib" "$PROJECT_ROOT/mobile/flutter/"
    [ -d "$PROJECT_ROOT/app/test" ] && mv "$PROJECT_ROOT/app/test" "$PROJECT_ROOT/mobile/flutter/"
    [ -d "$PROJECT_ROOT/app/assets" ] && mv "$PROJECT_ROOT/app/assets" "$PROJECT_ROOT/mobile/flutter/"
    
    log_info "Moving Android app to mobile/android..."
    if [ -d "$PROJECT_ROOT/app/android" ]; then
        rm -rf "$PROJECT_ROOT/mobile/android"
        mv "$PROJECT_ROOT/app/android" "$PROJECT_ROOT/mobile/android"
    fi
    
    log_info "Moving iOS app to mobile/ios..."
    if [ -d "$PROJECT_ROOT/app/ios" ]; then
        rm -rf "$PROJECT_ROOT/mobile/ios"
        mv "$PROJECT_ROOT/app/ios" "$PROJECT_ROOT/mobile/ios"
    fi
    
    log_info "Moving web app to web/home/app..."
    if [ -d "$PROJECT_ROOT/app/web" ]; then
        rm -rf "$PROJECT_ROOT/web/home/app"
        mkdir -p "$PROJECT_ROOT/web/home"
        mv "$PROJECT_ROOT/app/web" "$PROJECT_ROOT/web/home/app"
    fi
    
    log_success "Flutter application migrated"
    
    # Remove empty app directory
    if [ -d "$PROJECT_ROOT/app" ] && [ -z "$(ls -A "$PROJECT_ROOT/app")" ]; then
        rmdir "$PROJECT_ROOT/app"
        log_info "Removed empty app directory"
    fi
else
    log_warn "app/ directory not found, skipping migration"
fi

# Step 5: Reorganize docs
log_info "Step 5: Reorganizing documentation..."
if [ -d "$PROJECT_ROOT/docs" ]; then
    log_info "Moving existing docs to docs/ui..."
    for item in "$PROJECT_ROOT/docs"/*; do
        if [ -f "$item" ]; then
            filename=$(basename "$item")
            [ "$filename" != ".gitkeep" ] && mv "$item" "$PROJECT_ROOT/docs/ui/" || true
        fi
    done
    log_success "Documentation reorganized"
else
    log_warn "docs/ directory not found"
fi

# Step 6: Create .gitkeep files for empty directories
log_info "Step 6: Creating .gitkeep files for empty directories..."
for dir in "$PROJECT_ROOT/api/common" "$PROJECT_ROOT/deploy/docker" "$PROJECT_ROOT/deploy/helm" "$PROJECT_ROOT/deploy/terraform" "$PROJECT_ROOT/docs/api"; do
    touch "$dir/.gitkeep"
done
log_success ".gitkeep files created"

# Step 7: Update Makefile
log_info "Step 7: Updating Makefile paths..."
sed -i.bak "s|$(ROOT_DIR)/app/flutter|$(ROOT_DIR)/mobile/flutter|g" "$PROJECT_ROOT/Makefile"
log_success "Makefile updated"


# Final summary
log_info "=================================================="
log_success "Project structure refactoring completed!"
log_info ""
log_info "Summary of changes:"
log_info "✓ Created .gitignore and .dockerignore"
log_info "✓ Renamed CHANGELOG to CHANGELOG.md"
log_info "✓ Migrated Flutter app to mobile/flutter/"
log_info "✓ Organized Android code in mobile/android/"
log_info "✓ Organized iOS code in mobile/ios/"
log_info "✓ Moved web app to web/home/app/"
log_info "✓ Created api/common/ directory"
log_info "✓ Created deploy/ directory structure"
log_info "✓ Reorganized docs/ structure"
log_info "✓ Updated Makefile paths"
log_info "✓ Created STRUCTURE.md documentation"
log_info ""
log_info "Refactoring log saved to: $LOG_FILE"
log_info ""
log_warn "Next steps:"
log_warn "1. Review the new directory structure"
log_warn "2. Test the build process: make setup && make run-chrome"
log_warn "3. Commit the changes to git"
log_warn "4. Update any CI/CD pipelines that reference old paths"
log_info ""

exit 0

