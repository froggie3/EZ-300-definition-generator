#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DIST_DIR="$SCRIPT_DIR/dist"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

pushd $SCRIPT_DIR > /dev/null

# InstrumentListを変換
$SCRIPT_DIR/src/scrape_instrumentlist.sh

cat \
    $TEMPLATES_DIR/header.txt \
    <($SCRIPT_DIR/src/generate-instrumentlist.py $DIST_DIR/mapfile.txt $DIST_DIR/elementsfile.txt | \
      tail -n +2 | \
      sed -E 's/^/        /g') \
    $TEMPLATES_DIR/footer.txt | \
iconv -f utf-8 -t shift-jis \
> $DIST_DIR/EZ-J210_export.xml

# tee $DIST_DIR/EZ-J210_export.xml

popd > /dev/null