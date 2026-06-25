# Dotfiles — Hyprland + HyDE · Tema OLED Mono

Configuración personal de Arch Linux (Wayland): Hyprland, HyDE, Waybar, Hyprlock,
Rofi, Dunst, Kitty/Foot, Fish + Starship, temas GTK/Qt y tema **OLED Mono**.

Organizado con **GNU Stow** (cada carpeta en `stow/` refleja `$HOME`).

---

## Instalación en una máquina nueva

```bash
git clone https://github.com/gandhisagastume/archlinuxfiles-personal.git ~/dotfiles
cd ~/dotfiles

# 1) Pega tus wallpapers OLED Mono (no están en git, ver más abajo)
#    samurai.gif / swordbyn.gif / vagabond.gif  ->  stow/wallpaper/Wallpapers/

# 2) Ejecuta el bootstrap (NO como root)
./bootstrap.sh

# 3) Pon tu API key local
cp ~/.config/fish/secrets.fish.example ~/.config/fish/secrets.fish
$EDITOR ~/.config/fish/secrets.fish

# 4) Reinicia (obligatorio si tienes NVIDIA — carga módulos + activa SDDM)
reboot
```

`bootstrap.sh` hace, en orden:
1. Verifica Arch y detecta el AUR helper (paru/yay; instala paru si falta).
2. Instala paquetes desde `system/packages/pkglist.txt`.
3. **NVIDIA**: si detecta GPU NVIDIA instala drivers (`nvidia-open-dkms`,
   `nvidia-utils`, `egl-wayland`…), escribe el env de Wayland en
   `~/.config/hypr/nvidia.conf` y configura kernel modeset
   (mkinitcpio + `/etc/modprobe.d/nvidia.conf` + GRUB). En Intel/AMD se omite.
4. Despliega los dotfiles con `stow`.
5. Configura SDDM con tema Sugar-Candy (OLED Mono).
6. Genera colores con `matugen` a partir del wallpaper.

---

## Hardware objetivo

Pensado para **desktop con NVIDIA RTX 3070 + Intel i5-10400F**, pero el bootstrap
detecta la GPU y se adapta (sirve también en laptops Intel/AMD).

- **Monitores**: edita `~/.config/hypr/monitors.conf`. Trae preconfigurado un
  layout de 2 monitores (1080p@180 volteado + 1680x1050@60 vertical). Corre
  `hyprctl monitors all` para ver los nombres reales de puerto y ajústalos.

---

## Wallpapers (importante)

Los 3 gifs animados de OLED Mono **no están en git** (pesan ~250MB en total).
Cópialos a mano en `stow/wallpaper/Wallpapers/` antes del bootstrap.
Ver `stow/wallpaper/Wallpapers/README.md`.

---

## Secretos

Nunca se versionan claves. La API key va en `~/.config/fish/secrets.fish`
(ignorado por git). Usa `secrets.fish.example` como plantilla.

---

## Atajos clave (Hyprland)

| Atajo | Acción |
|-------|--------|
| `Super+T` | Terminal (Kitty) |
| `Super+E` | Archivos (Dolphin) |
| `Super+A` | Lanzador (Rofi) |
| `Super+F` | Firefox |
| `Super+Q` | Cerrar ventana |
| `Super+L` | Bloquear (Hyprlock) |
| `Super+Y` | Selector de tema |
| `Super+Shift+T` | Selector de wallpaper |
| `Super+Alt+←/→` | Ciclar wallpaper |
| `Super+Shift+M` | Alternar espejo/extendido |

Lista completa en `~/.config/hypr/keybindings.conf`.
