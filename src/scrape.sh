#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# 前処理スクリプト
# 表はPDFから全部コピペして貼り付ける
# プログラムチェンジが割り当てられてないやつは作業しないので貼り付けないこと
# （デュアルとかアルペジオとか）

# 作業ディレクトリに移動
pushd "$SCRIPT_DIR/.." > /dev/null

# 作業用ディレクトリを構築
export WORKDIR=`mktemp -d`
export ORIGINAL_DIR="$SCRIPT_DIR/../original/voices"
export DIST_DIR="$SCRIPT_DIR/../dist"
export TEMPLATES_DIR="$SCRIPT_DIR/../templates"


# 出力先ディレクトリ
mkdir -p $DIST_DIR 


# 
# InstrumentList を変換

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

# WORKDIRをきれいにしておく
rm $WORKDIR/*

#
# DrumSetList の生成

export BUCKET_FILE=`mktemp`
export INSERT_XML_FILE=`mktemp`

export DRUM_VOICES_START=`head -n1 "$SCRIPT_DIR/../original/drums/drum-voices.txt" | awk '{ print $1 }'`  # 242

# 指定した CC に対するドラムキットの組み合わせを取得する
function func() {
    paste \
        <( awk '{ print $2 }' "$SCRIPT_DIR/../original/drums/keys#-keyboard-midi.txt" ) \
        <( awk -F'\t' -v col=$1 '{ print $col }' "$SCRIPT_DIR/../original/drums/list.txt" ) \
        > "$WORKDIR/$((DRUM_VOICES_START+$1)).txt"
}

export -f func

# 指定した CC に対するドラムキットの組み合わせを生成
# ドラムセットは CC #242 ~ #264 の計 22 個: {1, 3..22}
seq 22 | xargs -n 1 bash -c 'func "$@"' _

# ls -la $WORKDIR

#
# 一時ファイル
#
# BUCKET_FILE=$(mktemp)
#
# # ファイルを結合し、一時ファイルに書き出し
# join -t $'\t' "$SCRIPT_DIR/../original/drums/msb-lsb-pc.txt" "$SCRIPT_DIR../original/drums/drum-voices.txt" > $BUCKET_FILE
#
# # 一括処理してコマンドを生成し、xargsで実行
# awk -F'\t' -v output_dir="$SCRIPT_DIR/../dist/drums" -v script_dir="$SCRIPT_DIR" -v sq="'" '
# {
#     # 1カラム目を ".txt" 拡張子付きのファイル名に変換
#     file = sprintf("%s/%03d.txt", output_dir, $1);
#     args = $2 " " $3 " " $4 " " sq $5 sq;
#     print file " " args;
# }
# ' "$BUCKET_FILE" | xargs -L 1 $SCRIPT_DIR/dump_drummap.py
#
# rm "$BUCKET_FILE"

#
# 以下のべた書きコードは上のコードをループ展開したものです （可読性の確保のため）

$SCRIPT_DIR/dump_drummap.py $WORKDIR/243.txt 127 0 88  'Power Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/244.txt 127 0 1   'Standard Kit 1' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/245.txt 127 0 2   'Standard Kit 2' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/246.txt 127 0 9   'Room Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/247.txt 127 0 17  'Rock Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/248.txt 127 0 25  'Electronic Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/249.txt 127 0 26  'Analog Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/250.txt 127 0 113 'Dance Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/251.txt 127 0 33  'Jazz Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/252.txt 127 0 41  'Brush Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/253.txt 127 0 49  'Symphony Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/254.txt 126 0 128 'StdKit 1 + Chinese Perc.' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/255.txt 126 0 40  'Indian Kit 1' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/256.txt 126 0 115 'Indian Kit 2' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/257.txt 126 0 55  'StdKit 1 + Indonesian Perc. 1' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/258.txt 126 0 56  'StdKit 1 + Indonesian Perc. 2' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/259.txt 126 0 57  'StdKit 1 + Indonesian Perc. 3' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/260.txt 126 0 37  'Arabic Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/261.txt 126 0 41  'Cuban Kit' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/262.txt 126 0 1   'SFX Kit 1' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/263.txt 126 0 2   'SFX Kit 2' >> $BUCKET_FILE
$SCRIPT_DIR/dump_drummap.py $WORKDIR/264.txt 126 0 113 'Sound Effect Kit' >> $BUCKET_FILE

# ls -la $BUCKET_FILE
# cat $BUCKET_FILE

#
# DrumSetList 生成終了

cat \
    <( $SCRIPT_DIR/generate-instrumentlist.py $DIST_DIR/mapfile.txt $DIST_DIR/elementsfile.txt | tail -n +2 ) \
    <( $SCRIPT_DIR/drumlist_from_bucket.py $BUCKET_FILE | tail -n +2 ) | \
    sed -E 's/^/        /g' \
    > $INSERT_XML_FILE

cat \
    $TEMPLATES_DIR/header.txt \
    $INSERT_XML_FILE \
    $TEMPLATES_DIR/footer.txt | \
    sed '/^ *$/d' | \
    iconv -f utf-8 -t shift-jis \
    > $DIST_DIR/EZ-J210_export.xml
    # tee $DIST_DIR/EZ-J210_export.xml

popd > /dev/null
rm -r "$TMPFILE" "$WORKDIR" "$BUCKET_FILE" "$INSERT_XML_FILE"
