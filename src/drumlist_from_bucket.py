#!/usr/bin/env python3

import sys
import argparse
import xml.etree.ElementTree as ET

from library import common

def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(
        description='複数の <Map> が同レベルに記述されているファイルから <DrumSetList> を生成します。',
    )
    parser.add_argument('drummap', type=str,
                        help='生成元 XML （`-` を指定すると標準入力を受け付けます）')
    args = parser.parse_args()

    print(
        args,
        file=sys.stderr  # sys.stderr
    )

    file = args.drummap if args.drummap != "-" else "/dev/stdin"

    with open(file, mode='r', encoding='utf-8') as file:
        whole_file_content = file.read()

        # Python XML: ParseError: junk after document element
        # https://stackoverflow.com/questions/38853644
        enclosed = "".join([
            '<Map Name="XG Lite">',
            whole_file_content,
            "</Map>"
        ])

        parsed = ET.fromstring(enclosed)
        root = ET.Element("DrumSetList")
        root.append(parsed)

        common.print_pretty_xml(root)


if __name__ == '__main__':
    main()
