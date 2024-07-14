#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# 前処理スクリプト
# 表はPDFから全部コピペして貼り付ける
# プログラムチェンジが割り当てられてないやつは作業しないので貼り付けないこと
# （デュアルとかアルペジオとか）

# 作業ディレクトリに移動
pushd "$SCRIPT_DIR/.." > /dev/null

# 作業用ディレクトリを構築
mkdir -pv "./working" "./dist"

# 大事な元ファイルをバックアップ
find "./original" -type f -exec cp -fv {} "working" \;

# データをクリーニング
pushd original > /dev/null
    for f in *.txt; do
        sed -E 's/ \*+//g' $f | \
        perl -pe 's/S\.Art Lite\n/S.Art Lite /g' > "../working/$f"
    done
popd > /dev/null

# （日本語のみ）
# https://superuser.com/questions/887578/using-perl-regex-over-multiple-lines
perl -i -0pe 's/スタンダードキット 1\n\+ インド/スタンダードキット 1 + インド/g' ./working/ja.txt

pushd working > /dev/null

# マップファイルを作成
paste \
    <(grep -A 1 -E '^[^0-9]*$' "ja.txt" | grep -E '[0-9]+' | awk '{ print $1 }') \
    <(grep -E '^[^0-9]*$' "ja.txt") \
    <(grep -E '^[^0-9]*$' "en.txt" | tr ' ' '_') \
    > "../dist/mapfile.txt"

for f in *.txt; do
    cp $f "$f~" 

    # データ行以外の行を削除し、ソートしてユニーク化
    cat "$f~" | \
    perl -pe 's/^[^0-9]+//g' | \
    sort -nk 1 | \
    uniq \
    > $f

    cp $f "$f~"

    # Joining multiple fields in text files on Unix
    # https://stackoverflow.com/questions/2619562/
    paste \
        <(awk '{ print $1"@"$2"@"$3"@"$4 }' "$f~") \
        <(cut -d ' ' -f 5- "$f~" | sed -E 's/ /_/g') \
        > $f
done

join ./*.txt | sed -E 's/@/ /g' | tee ../dist/elementsfile.txt

popd > /dev/null