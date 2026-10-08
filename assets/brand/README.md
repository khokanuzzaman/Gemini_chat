# PocketPilot brand assets (put this folder at assets/brand/)
Source of truth: the *.svg files (400-unit viewBox). PNGs are 1024px renders.

| File | Use |
| --- | --- |
| icon_square.svg/png | iOS AppIcon (no alpha, no rounding; iOS masks it) and the legacy Android icon |
| play_store_icon_512.png | Play Console hi-res icon (512, no alpha) |
| icon_rounded.svg/png | Marketing, web, About screen, onboarding |
| adaptive_background.svg/png | Android adaptive icon background layer |
| adaptive_foreground.svg/png | Android adaptive icon foreground (transparent; mark sits inside the 66/108 safe zone) |
| adaptive_monochrome.svg/png | Android 13+ themed icon (alpha only) |
| splash_mark.svg/png | Android 12+ splash icon, on icon_background_color #5647C4 (light and dark) |

Colours: gradient #5A4BCF to #352A80, glow brass #E0A83B at 28%, dot brass #E0A83B.
Pre-12 splash / in-app splash: icon_rounded centred on canvas (#F3F1FA light, #14121F dark).
In-app usage: prefer the SVGs via flutter_svg.
