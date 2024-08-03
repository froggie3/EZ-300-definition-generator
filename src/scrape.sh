#!/usr/bin/env bash

# 現在のスクリプトのディレクトリを取得
export SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# 作業ディレクトリに移動
cd "$SCRIPT_DIR/.."

# 作業用ディレクトリを構築
export WORKDIR=`mktemp -d`
export ORIGINAL_DIR="$SCRIPT_DIR/../original/voices"
export DIST_DIR="$SCRIPT_DIR/../dist"
export TEMPLATES_DIR="$SCRIPT_DIR/../templates"


# 出力先ディレクトリ
mkdir -p $DIST_DIR

# 大事な元ファイルをバックアップ
cp -f $ORIGINAL_DIR/* $WORKDIR

# ---------------- #
#                  #
#  InstrumentList  #
#                  #
# ---------------- #

#
# データをクリーニング
#

cp "$WORKDIR/en.txt" "$WORKDIR/en.txt.old"
cp "$WORKDIR/ja.txt" "$WORKDIR/ja.txt.old"

sed -E 's/ \*+//g' "$WORKDIR/en.txt.old" | perl -pe 's/S\.Art Lite\n/S.Art Lite /g' > "$WORKDIR/en.txt"
sed -E 's/ \*+//g' "$WORKDIR/ja.txt.old" | perl -pe 's/S\.Art Lite\n/S.Art Lite /g' > "$WORKDIR/ja.txt"

# 
# 日本語だけの処理
#
# 'perl -0pe' に関しては 'Using Perl regex over multiple lines' を参照
# https://superuser.com/questions/887578/using-perl-regex-over-multiple-lines
#

cp "$WORKDIR/ja.txt" "$WORKDIR/ja.txt.old"
perl -0pe 's/スタンダードキット 1\n\+ インド/スタンダードキット 1 + インド/g' "$WORKDIR/ja.txt.old" > "$WORKDIR/ja.txt"

pushd $WORKDIR > /dev/null


#
# マップファイルを作成
#

paste \
    <( grep -A 1 -E '^[^0-9]*$' ./ja.txt | grep -E '[0-9]+' | awk '{ print $1 }' ) \
    <( grep -E '^[^0-9]*$'      ./ja.txt ) \
    <( grep -E '^[^0-9]*$'      ./en.txt | tr ' ' '_' ) \
    > $WORKDIR/mapfile.txt


#
# 各マップの始点と終点を適切に計算させるため、番兵を置く
#

tail -1 ./en.txt | awk '{ print $1"\tNil\tNil" }' >> "$WORKDIR/mapfile.txt"


#
# 各マップの始点と終点を計算する
#

"$SCRIPT_DIR/calculate-range.py" "$WORKDIR/mapfile.txt" > "$WORKDIR/mapfile_ranged.txt"

# 
# データが存在しない行を削除し、ソートしてユニーク化
#
# E.PIANO // この行を削除 
# 8 0 118 5 Cool! SuitcaseEP
#

perl -pe 's/^[^0-9]+//g' "./ja.txt" | sort -nk1 | uniq > "./ja.txt.cleaned"
perl -pe 's/^[^0-9]+//g' "./en.txt" | sort -nk1 | uniq > "./en.txt.cleaned"


#
# 日本語と英語で同じフィールドを結合
#
# Joining multiple fields in text files on Unix
# https://stackoverflow.com/questions/2619562/
#

paste <( awk 'BEGIN { OFS="@" } { print $1, $2, $3, $4 }' "./ja.txt.cleaned" ) <( cut -d ' ' -f 5- "./ja.txt.cleaned" | sed -E 's/ /_/g' ) > "./ja.txt.joined"
paste <( awk 'BEGIN { OFS="@" } { print $1, $2, $3, $4 }' "./en.txt.cleaned" ) <( cut -d ' ' -f 5- "./en.txt.cleaned" | sed -E 's/ /_/g' ) > "./en.txt.joined"



#
# '@' で圧縮していたフィールドを展開
# join -t'\t' とすると join: multi-character tab '\\t' と怒られる
#
# Is it a bug for join with -t\t?
# https://unix.stackexchange.com/questions/46910/is-it-a-bug-for-join-with-t-t
#

join -t $'\t' ./{ja,en}.txt.joined | \
tr '@' '\t' | \
sort -n -k1 > $WORKDIR/elementsfile.txt



# --------------- #
#                 #
#   DrumSetList   #
#                 #
# --------------- #

export DRUM_VOICES_START=`head -n1 "$SCRIPT_DIR/../original/drums/drum-voices.txt" | awk '{ print $1 }'`  # 242

#
# 指定した CC に対するドラムキットの組み合わせを取得する
# ベースアドレスの 242 から加算していく
#

function func() {
    paste \
        <( awk '{ print $2 }' "$SCRIPT_DIR/../original/drums/keys#-keyboard-midi.txt" ) \
        <( awk -F'\t' -v col=$1 ' BEGIN { col += 1 } { print $col }' "$SCRIPT_DIR/../original/drums/list.txt" ) \
        > "$WORKDIR/$((DRUM_VOICES_START+$1)).txt"
}

export -f func

#
# 指定した CC に対するドラムキットの組み合わせを生成
# ドラムセットは CC #242 ~ #263 の計 22 個
#

seq 0 21 | xargs -n 1 bash -c 'func "$@"' _


#
# こんな感じのドラムの Tone リストを作成し、XML を生成する
# 1 カラム目の通し番号は対応するドラムキットの内容ファイル ([0-9]{3}.txt) に対応
#
# 242     127     0       88      Power Kit
# 243     127     0       1       Standard Kit 1
# 244     127     0       2       Standard Kit 2
# ...
#

join \
    -t $'\t' \
    "$SCRIPT_DIR/../original/drums/msb-lsb-pc.txt" \
    "$SCRIPT_DIR/../original/drums/drum-voices.txt" \
    > $WORKDIR/tonelist.txt


#
# Tone リストから動的に dump_drummap.py への引数を生成して実行（例）
#
# $SCRIPT_DIR/dump_drummap.py $WORKDIR/242.txt 127 0 88 'Power Kit' >> $WORKDIR/dr_bucket
# $SCRIPT_DIR/dump_drummap.py $WORKDIR/243.txt 127 0 1 'Standard Kit 1' >> $WORKDIR/dr_bucket
# $SCRIPT_DIR/dump_drummap.py $WORKDIR/244.txt 127 0 2 'Standard Kit 2' >> $WORKDIR/dr_bucket
# ...
#

awk -F'\t' -v output_dir="$WORKDIR" -v script_dir="$SCRIPT_DIR" -v sq="'" '
{
    print sprintf("%s/%03d.txt", output_dir, $1), $2, $3, $4, sprintf("%s%s%s", sq, $5, sq);
}
' "$WORKDIR/tonelist.txt" | \
tr '\n' '\0' | \
xargs -0 -l echo $SCRIPT_DIR/dump_drummap.py | bash - >> $WORKDIR/dr_bucket




#
# 合成
#

cat \
    <( $SCRIPT_DIR/generate-instrumentlist.py $WORKDIR/mapfile_ranged.txt $WORKDIR/elementsfile.txt | tail -n +2 ) \
    <( $SCRIPT_DIR/drumlist_from_bucket.py $WORKDIR/dr_bucket | tail -n +2 ) | \
    sed -E 's/^/        /g' \
    > $WORKDIR/xml_content

cat \
    $TEMPLATES_DIR/header.txt \
    $WORKDIR/xml_content \
    $TEMPLATES_DIR/footer.txt | \
    iconv -f utf-8 -t shift-jis \
    > $DIST_DIR/EZ-J210_export.xml
    # tee $DIST_DIR/EZ-J210_export.xml

popd > /dev/null

rm -r "$WORKDIR"
