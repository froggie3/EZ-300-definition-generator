#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree as ET

from library.common import debug_print, print_pretty_xml


def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(
        description='複数の <Map> が同レベルに記述されているファイルから <DrumSetList> を生成します。',
    )
    parser.add_argument('drummap', type=argparse.FileType(),
                        help='生成元 XML （`-` を指定すると標準入力を受け付けます）')
    args = parser.parse_args()

    debug_print(args)

    # Python XML: ParseError: junk after document element
    # https://stackoverflow.com/questions/38853644
    enclosed = "".join([
        '<Map Name="XG Lite">',
        *args.drummap,
        "</Map>"
    ])

    parsed = ET.fromstring(enclosed)
    root = ET.Element("DrumSetList")
    root.append(parsed)

    print_pretty_xml(root)


if __name__ == '__main__':
    main()
