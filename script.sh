#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# InstrumentListを変換
./src/scrape_instrumentlist.sh

cat \
    .example/header.txt \
    <(./src/generate-instrumentlist.py ./dist/mapfile.txt ./dist/elementsfile.txt | \
        tail -n +2 | \
        sed -E 's/^/        /g') \
    .example/footer.txt | \
tee dist/EZ-J210_export.xml
