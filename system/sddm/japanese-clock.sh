#!/bin/bash
# Update: Japanese Welcome, 150% bigger clock, 30% bigger date, chunky font

THEME_DIR="/usr/share/sddm/themes/Sugar-Candy"
CLOCK_QML="$THEME_DIR/Components/Clock.qml"
THEME_CONF="$THEME_DIR/theme.conf"

echo ""
echo "  Japanese Welcome + Big Chunky Clock"
echo "  ==================================="
echo ""

# Step 1: Install Montserrat (super chunky font)
echo "  [1/5] Installing Montserrat font..."
sudo pacman -S --needed --noconfirm ttf-montserrat 2>/dev/null || echo "  (may already be installed)"

# Step 2: Backup Clock.qml
echo "  [2/5] Backing up Clock.qml..."
if [ -f "$CLOCK_QML" ] && [ ! -f "$CLOCK_QML.backup" ]; then
    sudo cp "$CLOCK_QML" "$CLOCK_QML.backup"
    echo "  ✓ Backed up"
fi

# Step 3: Modify Clock.qml
echo "  [3/5] Modifying Clock.qml..."

if grep -q "font.weight: Font.Black" "$CLOCK_QML" 2>/dev/null; then
    echo "  (already modified, skipping)"
else
    # 3a: Time label - change ×3 to ×4.5 (150% bigger)
    sudo sed -i '/timeLabel/,/^    }/s/\* 3/\* 4.5/' "$CLOCK_QML"
    echo "  ✓ Time size: ×3 → ×4.5 (150% bigger)"

    # 3b: Time label - add Montserrat Black after font.pointSize
    sudo sed -i '/timeLabel/,/^    }/s/\(font\.pointSize.*\)/\1\n        font.family: "Montserrat"\n        font.weight: Font.Black/' "$CLOCK_QML"
    echo "  ✓ Time font: Montserrat Black (gordita)"

    # 3c: Date label - add font.pointSize ×1.3 after color
    sudo sed -i '/dateLabel/,/^    }/s/\(color: root\.palette\.text\)/\1\n        font.pointSize: root.font.pointSize * 1.3/' "$CLOCK_QML"
    echo "  ✓ Date size: ×1.3 (30% bigger)"
fi

# Step 4: Update theme.conf
echo "  [4/5] Updating theme.conf..."
sudo sed -i 's/HeaderText="Welcome!"/HeaderText="ようこそ"/' "$THEME_CONF"
echo "  ✓ Welcome → ようこそ"

# Step 5: Restart SDDM
echo "  [5/5] Restarting SDDM..."
sudo systemctl restart sddm

echo ""
echo "  Done! Changes:"
echo "    ようこそ - Japanese Welcome"
echo "    Clock: ×4.5 size, Montserrat Black"
echo "    Date:  ×1.3 size"
echo ""
