# 🚀 Instalación en máquina nueva (RTX 3070 + i5-10400F)

## Requisitos previos
- Arch Linux base ya instalado (tu usuario, `sudo`, internet).
- **Habilita multilib** (necesario para `lib32-nvidia-utils`). Edita
  `/etc/pacman.conf` y descomenta:
  ```
  [multilib]
  Include = /etc/pacman.d/mirrorlist
  ```
  Luego: `sudo pacman -Sy`

---

## Pasos

**1. Clona el repo**
```bash
git clone https://github.com/gandhisagastume/archlinuxfiles-personal.git ~/dotfiles
cd ~/dotfiles
```

**2. Pega tus 3 wallpapers** (no están en git por pesados)
```bash
cp /ruta/a/tus/gifs/{samurai,swordbyn,vagabond}.gif ~/dotfiles/stow/wallpaper/Wallpapers/
```

**3. Ejecuta el instalador** (NO como root)
```bash
./bootstrap.sh
```
Detecta la 3070 → instala drivers NVIDIA + kernel modeset → instala paquetes →
despliega configs con stow → configura SDDM (OLED Mono) → genera colores con matugen.

**4. Pon tu API key**
```bash
cp ~/.config/fish/secrets.fish.example ~/.config/fish/secrets.fish
nano ~/.config/fish/secrets.fish        # pega tu ANTHROPIC_API_KEY
```

**5. Reinicia** (obligatorio — carga módulos NVIDIA y activa SDDM)
```bash
reboot
```

---

## Después del primer arranque

Ajusta los monitores (los nombres de puerto casi seguro difieren):
```bash
hyprctl monitors all                 # ver nombres reales (DP-1, DP-2, HDMI-A-1...)
nano ~/.config/hypr/monitors.conf    # cámbialos ahí; ya está comentado cómo
hyprctl reload                       # aplica sin reiniciar
```
Layout preescrito: 1080p@180 volteado + 1050p vertical. Si el vertical queda al
revés, cambia `transform, 3` → `transform, 1`.

---

## Solución de problemas

| Problema | Solución |
|---|---|
| Pantalla negra/sin login tras reboot | `cat /sys/module/nvidia_drm/parameters/modeset` debe dar `Y` |
| Cursor invisible | `hyprctl setcursor Bibata-Modern-Ice 20` |
| Iconos/cursor faltan | `paru -S tela-circle-icon-theme-git bibata-cursor-theme` |
| Wallpaper no aparece | confirma que los gifs están en `~/Wallpapers/` |
| Falla `lib32-nvidia-utils` | no habilitaste multilib (ver requisitos) |

---

## Atajos clave (Hyprland)

`Super+T` terminal · `Super+A` lanzador · `Super+E` archivos · `Super+L` bloquear ·
`Super+Y` temas · `Super+Shift+T` wallpapers · `Super+Alt+←/→` ciclar wallpaper ·
`Super+Shift+M` espejo/extendido.

Lista completa en `~/.config/hypr/keybindings.conf`.
