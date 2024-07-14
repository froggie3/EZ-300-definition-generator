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
WORKDIR=`mktemp -d`

# 出力先ディレクトリ
mkdir -p ./dist

# 大事な元ファイルをバックアップ
find "./original" -type f -exec cp -f {} $WORKDIR \;

# データをクリーニング
pushd original > /dev/null
    for f in *.txt; do
        sed -E 's/ \*+//g' $f | \
        perl -pe 's/S\.Art Lite\n/S.Art Lite /g' > "$WORKDIR/$f"
    done
popd > /dev/null

# （日本語のみ）
# https://superuser.com/questions/887578/using-perl-regex-over-multiple-lines
perl -i -0pe 's/スタンダードキット 1\n\+ インド/スタンダードキット 1 + インド/g' $WORKDIR/ja.txt

pushd $WORKDIR > /dev/null

# マップファイルを作成
paste \
    <(grep -A 1 -E '^[^0-9]*$' ja.txt | grep -E '[0-9]+' | awk '{ print $1 }') \
    <(grep -E '^[^0-9]*$' ja.txt) \
    <(grep -E '^[^0-9]*$' en.txt | tr ' ' '_') \
    > $SCRIPT_DIR/../dist/mapfile.txt


# 各マップの始点と終点を適切に計算させるため、番兵を置く
TMPFILE=`mktemp`
tail -1 ./en.txt | awk '{ print $1"\tNil\tNil" }' >> $SCRIPT_DIR/../dist/mapfile.txt
cat $SCRIPT_DIR/../dist/mapfile.txt > $TMPFILE
cat $TMPFILE | $SCRIPT_DIR/../src/calculate-range.py > $SCRIPT_DIR/../dist/mapfile.txt

for f in *.txt; do
    cat $f > $TMPFILE 

    # データ行以外の行を削除し、ソートしてユニーク化
    cat $TMPFILE | \
    perl -pe 's/^[^0-9]+//g' | \
    sort -nk1 | \
    uniq \
    > $f

    # Joining multiple fields in text files on Unix
    # https://stackoverflow.com/questions/2619562/
    cat $f > $TMPFILE 
    paste \
        <(awk '{ print $1"@"$2"@"$3"@"$4 }' $TMPFILE) \
        <(cut -d ' ' -f 5- $TMPFILE | sed -E 's/ /_/g') \
        > $f

done

# join ./*.txt | sed -E 's/@/ /g' | tee $SCRIPT_DIR/../dist/elementsfile.txt
join ./*.txt | sort -n -k1,1 -k2,2 -k3,3 -k4,4 | sed -E 's/@/ /g' > $SCRIPT_DIR/../dist/elementsfile.txt

popd > /dev/null

rm -r $TMPFILE $WORKDIR
