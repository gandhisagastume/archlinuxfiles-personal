# archlinuxfiles-personal

> Dotfiles personales para Arch Linux con Hyprland + HyDE (tema **OLED Mono**) + NVIDIA

![Hyprland](https://img.shields.io/badge/WM-Hyprland-00ccff)
![HyDE](https://img.shields.io/badge/Theme-HyDE-ff69b4)
![Arch](https://img.shields.io/badge/Distro-Arch-1793d1)
![NVIDIA](https://img.shields.io/badge/GPU-NVIDIA-76b900)

## ✨ Características

- 🪟 **Hyprland** con 18+ animaciones, workspaces, window rules
- 🎨 **HyDE** theme manager con tema principal **OLED Mono** (negro/blanco puro)
- 🚀 **NVIDIA** auto-config (drivers open, kernel modeset, env vars Wayland)
- 🔐 **SDDM** con tema Sugar Candy + login animado + ようこそ
- 📊 **Waybar** con módulos custom (CPU, GPU, RAM, red, batería, wallpaper switch, etc.)
- 🎯 **Rofi** con iconos de apps y 13+ estilos
- 🐟 **Fish** shell + **Starship** prompt
- 🎬 **Fastfetch** con logos anime y colores OLED Mono
- 🖼️ **13 temas GTK** + **Matugen** para colores dinámicos

## 📦 Quick install

```bash
git clone https://github.com/gandhisagastume/archlinuxfiles-personal.git ~/dotfiles
cd ~/dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

El script detecta hardware, instala paquetes, configura NVIDIA (si aplica), y aplica
todos los symlinks con GNU Stow.

### Opciones

```bash
./bootstrap.sh --help          # ver todas las opciones
./bootstrap.sh --dry-run       # simular sin hacer cambios
./bootstrap.sh --skip-packages # saltar instalación de paquetes
./bootstrap.sh --skip-nvidia   # no configurar NVIDIA
./bootstrap.sh --skip-sddm     # no instalar SDDM
./bootstrap.sh --verbose       # más detalles
```

## 🗂️ Estructura

```
dotfiles/
├── bootstrap.sh              # instalador universal
├── README.md                 # este archivo
├── INSTALL.md                # guía detallada de instalación
├── .gitignore
├── stow/                     # paquetes GNU Stow
│   ├── hyprland/             # → ~/.config/hypr/
│   ├── hyde/                 # → ~/.config/hyde/
│   ├── waybar/               # → ~/.config/waybar/
│   ├── rofi/                 # → ~/.config/rofi/
│   ├── dunst/                # → ~/.config/dunst/
│   ├── kitty/                # → ~/.config/kitty/
│   ├── fish/                 # → ~/.config/fish/
│   ├── fastfetch/            # → ~/.config/fastfetch/
│   ├── matugen/              # → ~/.config/matugen/
│   ├── scripts/              # → ~/.local/share/bin/ (47 scripts)
│   ├── themes/               # → ~/.themes/ (13 temas GTK)
│   ├── wallpaper/            # → ~/Wallpapers/
│   ├── terminalphoto/        # → ~/terminalphoto/ (logos fastfetch)
│   ├── home/                 # → ~/ (.bashrc, .gtkrc-2.0, etc.)
│   └── ...                   # 25 paquetes total
└── system/
    ├── packages/
    │   └── pkglist.txt       # lista de paquetes (oficial + AUR)
    └── sddm/
        ├── Backgrounds/lock-image.png
        ├── theme.conf.user
        ├── sddm.conf.d-10-oled-mono.conf
        ├── install.sh        # instalador manual SDDM
        ├── animated-fix.sh   # convierte Image → AnimatedImage (GIF login)
        └── japanese-clock.sh # reloj grande + ようこそ
```

## 🎯 Keybindings principales

| Atajo | Acción |
|---|---|
| `Super+A` | Rofi launcher (drun) |
| `Super+Tab` | Rofi window switcher |
| `Super+Shift+E` | Rofi filebrowser |
| `Super+T` | Terminal (kitty) |
| `Super+E` | File manager (dolphin) |
| `Super+B` | Browser (firefox) |
| `Super+L` | Lock (hyprlock) |
| `Super+Backspace` | Logout menu (wlogout) |
| `Super+D` | Show desktop (workspace empty) |
| `Super+Alt+Right/Left` | Next/prev wallpaper |
| `Super+Shift+T` | Wallpaper picker |
| `Super+Shift+A` | Rofi style picker |
| `Super+Shift+M` | Toggle monitor mirror/extend |
| `Super+Y` | HyDE theme selector |
| `Super+/` | Show all keybinds |
| `Super+Alt+B` | Waybar layout switch |
| `Super+Ctrl+B` | Waybar style switch |
| `Print` | Screenshot all monitors |
| `Super+P` | Screenshot region |

Ver todos en `~/.config/hypr/keybindings.conf` o presiona `Super+/`.

## 🖥️ Hardware soportado

**Probado en:**
- **CPU:** Intel Core i5-10400F (también AMD/Intel genéricos)
- **GPU:** NVIDIA RTX 3070 (Ampere, también funciona con Turing+ y RTX 40xx)
- **Display:** 1× 1080p@180Hz + 1× 1680x1050@60Hz vertical

**Adaptable a:**
- AMD GPUs (cambiar driver NVIDIA → `xf86-video-amdgpu`)
- Intel iGPU (sin cambios, simplemente no detecta NVIDIA)
- Múltiples monitores de cualquier resolución

## 🔄 Workflow de actualizaciones

```bash
# En tu máquina actual, después de hacer cambios:
cd ~/dotfiles
git add -A
git commit -m "Descripción del cambio"
git push origin main

# En la otra máquina:
cd ~/dotfiles
git pull origin main
./bootstrap.sh --skip-packages   # solo reaplica configs
```

O con Stow directamente (más rápido):

```bash
cd ~/dotfiles/stow
stow --target=$HOME --restow hyprland   # reaplica un paquete
```

## 🐛 Troubleshooting

### Login muestra cuadrados vacíos (no hay iconos)

```bash
$AUR_HELPER -S tela-circle-icon-theme-git bibata-cursor-theme
gsettings set org.gnome.desktop.interface icon-theme Tela-circle-grey
gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Ice
```

### Waybar no muestra iconos Nerd Font

```bash
sudo pacman -S ttf-jetbrains-mono-nerd
fc-cache -fv
```

### NVIDIA no funciona después de instalar

```bash
# Verificar módulos
lsmod | grep nvidia

# Si no aparecen:
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo reboot
```

### SDDM no aparece

```bash
sudo systemctl status sddm
sudo systemctl enable --force sddm
```

### Wallpapers grandes (vagabond.gif = 199MB) no se incluyen en git

Copia manualmente:

```bash
# Desde tu backup
cp /path/to/backup/{samurai,swordbyn,vagabond}.gif ~/Wallpapers/
```

Ver `stow/wallpaper/Wallpapers/README.md` para más detalles.

## 📝 Notas

- **Iconos** (Tela-circle, Bibata) NO están en git (4GB). Se instalan via AUR.
- **vagabond.gif** (199MB) NO está en git (excede límite GitHub). Se copia manual.
- **secrets.fish** NUNCA se commitea. Hay `secrets.fish.example` como template.
- El tema **OLED Mono** es el principal. Otros 12 temas están en `~/.config/hyde/themes/`.

## 🤝 Inspirado en

- [HyDE Project](https://github.com/HyDE-Project/HyDE)
- [prasanthrangan/hyprdots](https://github.com/prasanthrangan/hyprdots)
- [JaKooLit/Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland)

## 📄 Licencia

MIT — úsalo, modifícalo, distribúyelo.
