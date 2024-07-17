#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# InstrumentList, DrumSetList を変換
$SCRIPT_DIR/src/scrape.sh
