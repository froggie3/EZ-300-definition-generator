#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# InstrumentListを変換
./src/scrape_instrumentlist.sh

cat \
    ./templates/header.txt \
    <(./src/generate-instrumentlist.py ./dist/mapfile.txt ./dist/elementsfile.txt | \
        tail -n +2 | \
        sed -E 's/^/        /g') \
    ./templates//footer.txt | \
iconv -f utf-8 -t shift-jis | \
tee ./dist/EZ-J210_export.xml
