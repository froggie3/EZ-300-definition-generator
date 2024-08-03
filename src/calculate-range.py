#!/usr/bin/env python3

import argparse
from itertools import pairwise

from library.common import debug_print


def calc_line_diff(current_line: list, next_line: list):
    """
    >>> "\\n".join(calc_line_diff(['1', 'ピアノ', 'PIANO'], ['8', 'エレピ', 'E.PIANO']))
    '1\\t8\\tピアノ\\tPIANO'
    """
    current_start, *ret = current_line
    next_start, *_ = next_line
    yield "\t".join([current_start, next_start, *ret])


def main():
    parser = argparse.ArgumentParser(
        description='マップファイルの 2 つのレコードの通し番号から、 '
        '1 レコードに相当する範囲を計算します。',
    )
    parser.add_argument('mapfile', type=argparse.FileType(),
                        help='マップファイル （`-` を指定すると標準入力を受け付けます）')
    args = parser.parse_args()
    debug_print(args)

    iterator = (x.strip().split("\t") for x in args.mapfile)

    for first, second in pairwise(iterator):
        print("\n".join(calc_line_diff(first, second)))


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    main()
