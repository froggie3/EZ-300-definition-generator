#!/usr/bin/env python3

import argparse
import itertools


def calc_line_diff(current: list, next: list):
    """
    >>> "\\n".join(calc_line_diff(['1', 'ピアノ', 'PIANO'], ['8', 'エレピ', 'E.PIANO']))
    '1\\t8\\tピアノ\\tPIANO'
    """
    current_start, *ret = current
    next_start, *_ = next
    yield "\t".join([current_start, next_start, *ret])


def main():
    parser = argparse.ArgumentParser(
        description='マップファイルの 2 つのレコードの通し番号から、 '
        '1 レコードに相当する範囲を計算します。',
    )
    parser.add_argument('mapfile', type=argparse.FileType(),
                        help='マップファイル （`-` を指定すると標準入力を受け付けます）')
    args = parser.parse_args()
    for current, next in itertools.pairwise(
            x.strip().split("\t") for x in args.mapfile):
        print("\n".join(calc_line_diff(current, next)))


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    main()
