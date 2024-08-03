# EZ-300 definition generator

This script generates a [sound definition file](https://takabosoft.com/domino/module) for the MIDI sequencer [Domino](https://takabosoft.com/domino/) from the data (`original/*`) extracted from the YAMAHA [EZ-J300](https://jp.yamaha.com/products/musical_instruments/keyboards/portable_keyboards/ez-300/index.html)
owners manual ([ja](https://jp.yamaha.com/files/download/other_assets/4/1350754/ez300_ja_om_c0.pdf) / [en](https://jp.yamaha.com/files/download/other_assets/5/1350755/ez300_en_single_om_c0.pdf)).  
The drumset list was extracted from another document which are available in [japanese](https://jp.yamaha.com/files/download/other_assets/4/1353124/ez300_ja_dkl_a0.pdf) or [english](https://jp.yamaha.com/files/download/other_assets/3/1353133/ez300_en_fr_es_de_dkl_a0.pdf).

Execute the pre-processing script `./script.sh`.
The finished product is in `dist/EZ-300_export.xml`.

# Note

Some patches that does not have a program change assigned was not extracted, such as dual or arpeggio.

