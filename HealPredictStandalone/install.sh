#!/bin/bash
# HealPredictStandalone Installation Script for Linux/macOS

echo "HealPredictStandalone Installation Helper"
echo "========================================"
echo ""

# Common WoW paths
WOW_PATHS=(
    "$HOME/.wine/drive_c/Program Files (x86)/World of Warcraft"
    "$HOME/.wine/drive_c/Program Files/World of Warcraft"
    "/Applications/World of Warcraft"
    "$HOME/Games/world-of-warcraft"
    "$HOME/World of Warcraft"
)

ADDONS_DIR=""

# Find WoW installation
for path in "${WOW_PATHS[@]}"; do
    if [ -d "$path/Interface/AddOns" ]; then
        ADDONS_DIR="$path/Interface/AddOns"
        break
    fi
done

if [ -z "$ADDONS_DIR" ]; then
    echo "Could not find World of Warcraft installation directory."
    echo "Please manually copy the HealPredictStandalone folder to:"
    echo "  <WoW Directory>/Interface/AddOns/"
    echo ""
    echo "Common locations:"
    for path in "${WOW_PATHS[@]}"; do
        echo "  $path/Interface/AddOns/"
    done
    exit 1
fi

echo "Found WoW AddOns directory: $ADDONS_DIR"
echo ""

# Copy addon
if [ -d "HealPredictStandalone" ]; then
    echo "Copying HealPredictStandalone to AddOns directory..."
    cp -r "HealPredictStandalone" "$ADDONS_DIR/"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Installation completed successfully!"
        echo ""
        echo "Next steps:"
        echo "1. Start World of Warcraft"
        echo "2. Enable HealPredictStandalone in the AddOns list"
        echo "3. Use /healpredict config to configure settings"
        echo ""
    else
        echo "✗ Installation failed. Please install manually."
    fi
else
    echo "✗ HealPredictStandalone folder not found in current directory."
    echo "Please run this script from the directory containing the addon."
fi