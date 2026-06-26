# 📋 Guía de Instalación Detallada

> Paso a paso para instalar los dotfiles en una máquina Arch Linux nueva.

## 🎯 Antes de empezar

**Requisitos:**
- Arch Linux recién instalado (o existente)
- Conexión a internet
- Acceso sudo
- Git instalado (`sudo pacman -S git`)

**Si acabas de instalar Arch:**
1. Completa la instalación base
2. Crea tu usuario
3. Instala `git sudo base-devel`
4. Conecta a internet (`iwctl` o ethernet)
5. Continúa con esta guía

---

## 🚀 Instalación Express (5 minutos)

```bash
git clone https://github.com/gandhisagastume/archlinuxfiles-personal.git ~/dotfiles
cd ~/dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

Después:
```bash
# Pega tus wallpapers grandes
cp /path/to/backup/{samurai,swordbyn,vagabond}.gif ~/Wallpapers/

# Configura secrets
cp ~/.config/fish/secrets.fish.example ~/.config/fish/secrets.fish
$EDITOR ~/.config/fish/secrets.fish

# Verifica monitores
hyprctl monitors all
# Ajusta ~/.config/hypr/monitors.conf si es necesario

# Reinicia (carga drivers NVIDIA y SDDM)
sudo reboot
```

---

## 🔧 Instalación Detallada (paso a paso)

### Paso 1: Instalar paquetes base (sin dotfiles)

```bash
# Instalar paquetes esenciales
sudo pacman -S --needed git base-devel sudo

# Instalar AUR helper (paru es el más popular)
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
cd .. && rm -rf paru-bin

# Instalar dependencias críticas
sudo pacman -S --needed \
    hyprland hyprlock hypridle hyprpicker \
    waybar rofi-wayland kitty \
    dunst swww matugen \
    fish starship fastfetch \
    sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg

# AUR
paru -S --needed sddm-theme-sugar-candy-git \
    tela-circle-icon-theme-git bibata-cursor-theme \
    ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd
```

### Paso 2: Clonar dotfiles

```bash
git clone https://github.com/gandhisagastume/archlinuxfiles-personal.git ~/dotfiles
cd ~/dotfiles
chmod +x bootstrap.sh
```

### Paso 3: Ejecutar bootstrap

```bash
./bootstrap.sh
```

Esto:
1. Detecta tu hardware (NVIDIA sí/no)
2. Instala paquetes restantes
3. Configura NVIDIA (drivers, kernel modeset, env vars)
4. Aplica todos los symlinks con Stow
5. Instala SDDM con tema OLED Mono
6. Genera colores iniciales con matugen

### Paso 4: Post-instalación

#### Wallpapers grandes (NO en git)

```bash
# Copia tus 3 wallpapers animados a ~/Wallpapers/
cp /backup/samurai.gif ~/Wallpapers/
cp /backup/swordbyn.gif ~/Wallpapers/
cp /backup/vagabond.gif ~/Wallpapers/
```

#### Secrets

```bash
cp ~/.config/fish/secrets.fish.example ~/.config/fish/secrets.fish
$EDITOR ~/.config/fish/secrets.fish
```

#### Monitores

```bash
# Ver nombres de puertos
hyprctl monitors all

# Editar config
$EDITOR ~/.config/hypr/monitors.conf
```

Ajusta `DP-1`, `DP-2` por los nombres reales de tu hardware.

#### Reiniciar

```bash
sudo reboot
```

---

## 🐛 Troubleshooting

### "Write access not granted" al hacer push

Regenera tu token con scope `repo`:
https://github.com/settings/tokens

### SDDM no muestra el wallpaper

```bash
# Verificar archivo
ls -la /usr/share/sddm/themes/Sugar-Candy/Backgrounds/lock-image.png

# Si no existe, copiar manualmente
sudo cp ~/dotfiles/system/sddm/Backgrounds/lock-image.png \
    /usr/share/sddm/themes/Sugar-Candy/Backgrounds/
```

### NVIDIA: pantalla negra al login

```bash
# Ctrl+Alt+F2 para TTY
sudo vim /etc/mkinitcpio.conf
# Verificar MODULES=(... nvidia nvidia_modeset nvidia_uvm nvidia_drm)
sudo mkinitcpio -P
sudo reboot
```

### Waybar no arranca

```bash
# Ver errores
waybar -l

# Si dice "no se encuentra config":
ls -la ~/.config/waybar/
# Debe ser un symlink a ~/dotfiles/stow/waybar/.config/waybar/

# Si falta:
cd ~/dotfiles/stow
stow --target=$HOME --restow waybar
```

### Hyprland no carga

```bash
# Ver config
Hyprland -d
# Lee los errores en stderr
```

### Stow falla: "target already exists"

```bash
cd ~/dotfiles/stow/<paquete>
# Borrar archivos conflictivos manualmente
rm ~/.config/ejemplo/archivo_conflictivo
stow --target=$HOME --restow .
```

---

## 🏗️ Estructura de Stow

Cada subdirectorio en `stow/` es un paquete independiente:

```
stow/hyprland/.config/hypr/  →  ~/.config/hypr/  (symlink)
stow/waybar/.config/waybar/  →  ~/.config/waybar/  (symlink)
```

**Ventajas:**
- Editas en `~/dotfiles/stow/...` y se refleja en `~/.config/...`
- `git pull` + `stow --restow` = todo actualizado
- Cada paquete se puede (des)instalar independientemente

---

## 🔄 Mantenimiento

### Aplicar cambios después de editar configs

```bash
# En tu máquina de desarrollo
cd ~/dotfiles
$EDITOR stow/hyprland/.config/hypr/keybindings.conf
./dotfiles push "Update keybindings"
```

### Replicar cambios en la otra máquina

```bash
cd ~/dotfiles
git pull origin main
./bootstrap.sh --skip-packages --skip-nvidia   # solo reaplica configs
```

O más rápido:

```bash
cd ~/dotfiles
git pull
./dotfiles restow hyprland   # reaplica solo hyprland
```

### Agregar un nuevo paquete

```bash
# 1. Crear estructura
mkdir -p ~/dotfiles/stow/nuevo/.config/nuevo

# 2. Copiar config del sistema
cp ~/.config/nuevo/* ~/dotfiles/stow/nuevo/.config/nuevo/

# 3. Agregar a bootstrap.sh lista STOW_PACKAGES
# 4. Commit + push
cd ~/dotfiles
git add stow/nuevo
git commit -m "Add nuevo package"
git push
```

---

## 📞 Soporte

Si algo no funciona:

1. Revisa los logs: `cat /tmp/hypr/$(ls -t /tmp/hypr/ | head -1)/hyprland.log`
2. Verifica los symlinks: `./dotfiles status`
3. Compara con el repo: `./dotfiles diff`
4. Abre un issue en GitHub con la salida de:
   ```bash
   cat /etc/os-release
   lspci -mm | grep -i 'vga\|3d'
   ./dotfiles status
   ```
