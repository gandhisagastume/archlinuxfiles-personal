# Wallpapers (tema OLED Mono)

Los 3 wallpapers animados de OLED Mono **NO están versionados en git** porque pesan
demasiado (samurai.gif ~23MB, swordbyn.gif ~26MB, vagabond.gif ~199MB).

## Cómo dejarlos listos en una máquina nueva

1. Clona el repo y copia tus 3 gifs **dentro de esta carpeta**
   (`stow/wallpaper/Wallpapers/`):
   - `samurai.gif`
   - `swordbyn.gif`
   - `vagabond.gif`
2. Corre `./bootstrap.sh` (o `stow wallpaper`). Esto crea el symlink
   `~/Wallpapers` → esta carpeta, así que los gifs quedan disponibles para swww
   y para el selector de wallpapers de HyDE.

> Alternativa: si ya stoweaste, también puedes pegar los gifs directamente en
> `~/Wallpapers/` (es el mismo destino vía symlink).

Las miniaturas/PNG del tema (`~/.config/hyde/themes/OLED Mono/wallpapers/*.png`)
sí están en git porque son pequeñas; HyDE las usa para previews y matugen.
