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
ORIGINAL_DIR="$SCRIPT_DIR/../original/voices"
DIST_DIR="$SCRIPT_DIR/../dist"


# 出力先ディレクトリ
mkdir -p $DIST_DIR 

# 大事な元ファイルをバックアップ
find "$ORIGINAL_DIR" -type f -exec cp -f {} $WORKDIR \;

# データをクリーニング
pushd "$ORIGINAL_DIR" > /dev/null
    for f in *.txt; do
        sed -E 's/ \*+//g' $f | \
        perl -pe 's/S\.Art Lite\n/S.Art Lite /g' > "$WORKDIR/$f"
    done
popd > /dev/null

# 日本語のみ変なのでクリーニング
# Using Perl regex over multiple lines
# https://superuser.com/questions/887578/using-perl-regex-over-multiple-lines
perl -i -0pe 's/スタンダードキット 1\n\+ インド/スタンダードキット 1 + インド/g' $WORKDIR/ja.txt

pushd $WORKDIR > /dev/null

# マップファイルを作成
paste \
    <( grep -A 1 -E '^[^0-9]*$' ./ja.txt | grep -E '[0-9]+' | awk '{ print $1 }' ) \
    <( grep -E '^[^0-9]*$' ./ja.txt ) \
    <( grep -E '^[^0-9]*$' ./en.txt | tr ' ' '_' ) \
    > $DIST_DIR/mapfile.txt


# 各マップの始点と終点を適切に計算させるため、番兵を置く
TMPFILE=`mktemp`
tail -1 ./en.txt | awk '{ print $1"\tNil\tNil" }' >> $DIST_DIR/mapfile.txt
cat $DIST_DIR/mapfile.txt > $TMPFILE

# 各マップの始点と終点を計算する自作スクリプト + 合体
cat $TMPFILE | $SCRIPT_DIR/../src/calculate-range.py > $DIST_DIR/mapfile.txt

for f in *.txt; do
    cat $f > $TMPFILE 

    # データが存在しない行を削除し、ソートしてユニーク化
    # E.PIANO <---- これ
    # 8 0 118 5 Cool! SuitcaseEP
    cat $TMPFILE | \
    perl -pe 's/^[^0-9]+//g' | \
    sort -nk1 | \
    uniq \
    > $f

    # 日本語と英語で同じフィールドを結合
    # Joining multiple fields in text files on Unix
    # https://stackoverflow.com/questions/2619562/
    cat $f > $TMPFILE 
    paste \
        <( awk '{ print $1"@"$2"@"$3"@"$4 }' $TMPFILE ) \
        <( cut -d ' ' -f 5- $TMPFILE | sed -E 's/ /_/g' ) \
        > $f

done

# '@' で圧縮していたフィールドを展開
# join -t'\t' とすると join: multi-character tab '\\t' と怒られる
# Is it a bug for join with -t\t?
# https://unix.stackexchange.com/questions/46910/is-it-a-bug-for-join-with-t-t
join -t $'\t' ./*.txt | \
sed -E 's/@/\t/g' | \
sort -n -k1 > $DIST_DIR/elementsfile.txt

popd > /dev/null

rm -r $TMPFILE $WORKDIR
