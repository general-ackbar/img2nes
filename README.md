# img2nes

Converts a photo or image into NES background graphics — tiles, a nametable, an attribute
table and a palette — plus a ready-to-assemble NESASM source file that displays the result on
real hardware or in an emulator.

```bash
img2nes -i photo.jpg
```

That writes `photo.chr`, `photo.nmt`, `photo.pal` and `photo.asm`. Assemble the `.asm` with
NESASM and you have a ROM that shows the picture.

## Building

macOS, Objective-C, no dependencies beyond the system frameworks.

```bash
xcodebuild -project img2nes.xcodeproj -scheme img2nes -configuration Release
```

## What the NES gives you to work with

The constraints are the whole problem, and they are worth stating plainly because they explain
every design decision in the converter:

- **A background is 32 by 30 tiles** of 8 by 8 pixels, each tile using four colours.
- **Colour is assigned in blocks, not per tile.** One attribute byte covers 32 by 32 pixels
  and splits it into four 16 by 16 quadrants, two bits each, choosing one of four palettes.
  This is why NES artwork looks the way it does.
- **Every palette shares its first entry**, so the real budget is one common background
  colour plus four palettes of three colours — thirteen colours on screen.
- **The background pattern table holds 256 tiles.** Tile 0 is kept blank so the area around
  the image is a flat colour, which leaves 255 for the picture itself.

A nametable byte is eight bits, so 256 tiles is not a setting — it is the hardware.

## How the conversion works

**Colours.** The image is reduced to at most thirteen NES colours (`-m`), the most common one
becoming the shared background. The four palettes are then chosen by clustering: the most
frequent three-colour combinations seed them, and four rounds of assign-and-refit move them to
where they cover the image best.

**Tiles.** Every 8 by 8 block is converted to a two-bit pattern, then all of them are
collected before any tile is allocated. Identical patterns share a tile. When the image needs
more than 255 distinct patterns — which any photograph does — the 255 that are kept are chosen
by Lloyd's algorithm on the pixel values, and everything else is mapped to its closest match.
Because the distance measure is a sum of differences, the cluster centre is the median rather
than the mean.

**Attributes.** Written with the hardware's own quadrant formula. When the image is centred,
the offset is rounded down to an even number of tiles: an odd offset would put the image's
16 by 16 blocks across two quadrants, and then no assignment of palettes can be correct.

## How good is the result?

Honestly: **small pictures look good, full screens cannot.** The reason is arithmetic, not
effort.

| Image | Blocks needed | Distinct tiles needed | Result |
|---|---|---|---|
| 128×128 | 256 | 128 — fits | nothing approximated |
| 192×176 | 528 | ~480 | 11% approximated |
| 256×240 | 960 | 500–700 | over half approximated |

Photographs almost never repeat: 67% of the tiles in a full-screen photo occur exactly once,
and over 90% in a portrait. So tile reuse buys very little, and a full screen asks for roughly
four times what the same budget can hold. `-C` is the sweet spot — 128 by 128 lands just under
the limit with tiles to spare.

The converter warns you when more than 30% of the blocks had to settle for an approximation,
and suggests only the settings that would actually help.

**Dithering (`-d`) usually makes things worse**, badly so on large images: it raises the
approximation rate on a full-screen photo from 53% to 73%, because dithering invents detail
and detail is exactly what the tile budget cannot afford. It is off by default and is worth
trying only on small, flat motifs.

## Options

| | |
|---|---|
| `-i <file>` | Input image. Max 256×240, both sides divisible by 8 — unless `-F` or `-C`. |
| `-o <name>` | Output name without extension. Defaults to the input name. |
| `-t` | Anchor at the top left instead of centring. |
| `-F` | Fullscreen: scale to 256×240 ignoring aspect ratio, fewer colours, no dithering. |
| `-C` | Centred: as `-F` but scaled to 128×128, with the full colour budget. |
| `-d` | Dither instead of picking the closest colour. |
| `-m <n>` | Maximum number of NES colours (default 13). |
| `-g <$xx>` | Force the background colour, e.g. `-g $0F`. |
| `-l <file>` | Load a 16-byte binary palette instead of choosing one. |
| `-s <0-2>` | System palette: 0 Mesen, 1 FCEUX, 2 legacy. |
| `-b` | Write a `.nesgfx` project bundle instead of separate files. |
| `-x` | Write attributes as a separate `.attr` file instead of appending them to the nametable. |
| `-p` | Also write a PNG preview of the reduced image. |
| `-v <0-3>` | Verbosity. 2 or higher prints the attribute table. |
| `-h` | Help. |

The image is centred by default. `-c` is still accepted so older command lines keep working.
An explicit `-m` or `-d` wins over `-F` and `-C` regardless of the order on the command line.

## Output

| | |
|---|---|
| `<name>.chr` | 8 KB pattern table. The background half starts at offset 4096 (`$1000`). |
| `<name>.nmt` | 1024 bytes: 960 nametable followed by the 64 attribute bytes. |
| `<name>.pal` | 32 bytes: the four background palettes, written twice. The NES palette RAM is 32 bytes and the second half holds the sprite palettes, so the copy keeps sprites on the same colours instead of leaving them undefined. |
| `<name>.asm` | NESASM source that includes the three files above and displays the image. |
| `<name>.attr` | Only with `-x`; the nametable is then a plain 960 bytes. |
| `<name>_preview.png` | Only with `-p`; the colour-reduced image before tiling. |
| `<name>.nesgfx` | Only with `-b`; a project bundle for NESgfx. |

## Checking the result

`tools/render.m` draws a set of `.nmt` + `.chr` + `.pal` files exactly as the PPU would, and
writes it as a PNG. This is the only reliable way to tell whether the attributes actually
landed where they should — the conversion statistics can look perfectly healthy while the
picture is a block out of alignment.

```bash
clang -fobjc-arc -framework Cocoa tools/render.m -o render
./render photo            # reads photo.nmt/.chr/.pal, writes photo_nes.png
```

## Several images at once

`img2nes/merge.sh` converts every PNG in a folder and concatenates the results into one set of
files — `frames.nmt`, `data.chr` and `colors.pal` — for a slideshow that steps through the
frames on the console.

## Related tools

- **NESgfx** opens the `.nesgfx` bundles written by `-b`, for editing the screen by hand
  afterwards.
- **CHREditor** edits the `.chr` tiles directly.
