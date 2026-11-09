Castle of Shikigami II - Patch Build Kit
========================================

For those interested in seeing how the patch build process works, or in
modifying this patch for their own language, I've included a portable
kit with all the relevant tooling.

The kit doesn't include the game's text or graphics. Those are pulled
from a patched copy of the game when you run _01_extract_sources.bat.

The kit runs on Windows and needs Strawberry Perl, along with the Imager
and CamelROM modules. CamelROM can be found here:
https://github.com/DerekPascarella/CamelROM

Before you start, copy these files in:

1. gdi_orig
   The TOSEC Japanese Dreamcast dump "Shikigami no Shiro II":
    - Shikigami no Shiro II v1.002 (2004)(Alfa System)(JP)[!].gdi
    - track01.bin
    - track02.raw
    - track03.bin

2. gdi_patched
   The same dump with this English patch applied:
    - disc.gdi
    - track01.bin
    - track02.raw
    - track03.bin

Then run the BAT files in order:

_01_extract_sources.bat  - Extracts both discs and pulls the English text and graphics from the patched one.
_02_build_text.bat       - Inserts the English dialogue and menu text.
_03_build_graphics.bat   - Inserts the font and English graphics.
_04_patch_executable.bat - Applies the code patches and the bootsector patch.
_05_build_gdi.bat        - Builds the finished GDI in the gdi folder.

The finished disc image is in the gdi folder.

Running _01 again resets the extracted disc folders, but it leaves the
text and texture files in custom_tools alone so your edits are kept. If
you want the patch's original version of a file back, delete it and run
_01 again.

The custom_tools\reference folder has the script I used to extract the
PS2 and Steam demo assets. It isn't needed for this rebuild kit, but
I've left it in for anyone curious.