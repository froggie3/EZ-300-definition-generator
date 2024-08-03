#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree as ET

from library import common
from library.common import debug_print


def build_tree(args, iterator):
    root = ET.Element("PC", Name=args.name, PC=args.pc)
    bank = ET.SubElement(root, "Bank", Name=args.name, MSB=args.msb,
                         LSB=args.lsb)

    for key, name in iterator:
        if name != common.MASK_STRING:
            ET.SubElement(bank, "Tone", Name=name, Key=key)

    return root


def main():
    """
    メイン処理

    使用例:
        cat ../dist/drums/243.txt | ./generate-drumlist.py - 126 0 1 'SFX Kit 1'
        echo "23\tSeq Click L" | ./generate-drumlist.py - 126 0 1 'SFX Kit 1' 2>/dev/null
    """
    parser = argparse.ArgumentParser(
        description='プログラムチェンジに対応する Tone リストから XML ファイルを生成します。',
    )
    parser.add_argument('tonefile', type=argparse.FileType(),
                        help='Tone リスト （`-` を指定すると標準入力を受け付けます）')
    parser.add_argument('msb', type=str, help='MSB')
    parser.add_argument('lsb', type=str, help='LSB')
    parser.add_argument('pc', type=str, help='プログラムチェンジ番号')
    parser.add_argument('name', type=str, help='プログラムチェンジ名')
    args = parser.parse_args()

    debug_print(args)

    iterator = (x.strip().split("\t") for x in args.tonefile)
    root = build_tree(args, iterator)
    common.print_xml(root)


if __name__ == '__main__':
    main()
