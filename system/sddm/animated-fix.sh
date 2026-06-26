#!/bin/bash
# Fix: Convert background Image to AnimatedImage in Sugar Candy Main.qml
# This enables animated GIF playback as login background

THEME_DIR="/usr/share/sddm/themes/Sugar-Candy"
MAIN_QML="$THEME_DIR/Main.qml"

echo ""
echo "  Enabling animated GIF background"
echo "  ================================="
echo ""

if [ ! -f "$MAIN_QML" ]; then
    echo "  ERROR: Main.qml not found at $MAIN_QML"
    exit 1
fi

# Backup original
if [ ! -f "$MAIN_QML.backup" ]; then
    sudo cp "$MAIN_QML" "$MAIN_QML.backup"
    echo "  [1] Backed up Main.qml → Main.qml.backup"
else
    echo "  [1] Backup already exists"
fi

# Change Image to AnimatedImage (only the background, Main.qml has 1 Image block)
echo "  [2] Changing Image → AnimatedImage..."
sudo sed -i 's/^        Image {$/        AnimatedImage {/' "$MAIN_QML"

# Remove cache: true (prevents GIF animation)
echo "  [3] Removing cache:true (blocks animation)..."
sudo sed -i '/id: backgroundImage/,/^        }/{
    /cache: true/d
}' "$MAIN_QML"

# Verify changes
echo "  [4] Verifying changes..."
if grep -q "AnimatedImage {" "$MAIN_QML"; then
    echo "  ✓ AnimatedImage found in Main.qml"
else
    echo "  ✗ ERROR: AnimatedImage not found!"
    sudo cp "$MAIN_QML.backup" "$MAIN_QML"
    echo "  Restored backup. Nothing changed."
    exit 1
fi

if ! grep -q "cache: true" "$MAIN_QML"; then
    echo "  ✓ cache:true removed"
else
    echo "  ✗ WARNING: cache:true still present"
fi

echo "  [5] Restarting SDDM..."
sudo systemctl restart sddm

echo ""
echo "  Done! The GIF should now animate."
echo "  To undo: sudo cp $MAIN_QML.backup $MAIN_QML"
echo ""
