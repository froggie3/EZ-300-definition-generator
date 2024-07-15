#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ORIGINAL_DIR="$SCRIPT_DIR/../original/drums"
# TMP_DIR=`mktemp -d`
TMP_DIR="/home/iigau/toy/define-file/dist/drums"
mkdir -p $TMP_DIR

pushd $SCRIPT_DIR > /dev/null


# MIDI ノート番号（2列目）とドラムキット名の組み合わせを取得する
# ドラムキット名の取得では、スタンダードドラム（2列目）を基準に、n 列目をオーバーラップさせて出力
# Note: ドラムセットは CC #242 ~ #264 の計 22 個: {1, 3..22}

DRUM_VOICES_START=`head -n1 "$ORIGINAL_DIR/drum-voices.txt" | awk '{ print $1 }'`  # 242
DRUM_VOICES_END=`tail -n1 "$ORIGINAL_DIR/drum-voices.txt" | awk '{ print $1 }'`    # 263

for i in {1..22}; do
    if [ $i -eq 2 ]; then
        continue
    fi
    paste \
        <( awk '{ print $2 }' "$ORIGINAL_DIR/keys#-keyboard-midi.txt" ) \
        <( awk -F'\t' -v "override_column=$i" '{ print $override_column ? $override_column : $3 }' "$ORIGINAL_DIR/list.txt" ) \
        > "$TMP_DIR/$((DRUM_VOICES_START+i)).txt" \
         
done

# drum-voices.txt
# rm -r $TMP_DIR

popd > /dev/null

