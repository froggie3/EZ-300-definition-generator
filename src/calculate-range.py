#!/usr/bin/env python3

import sys
import itertools


def readlines_wrapper(lines):
    """
    >>> "\\n".join(readlines_wrapper(['9999 aaa\\n']))
    ''
    >>> "\\n".join(readlines_wrapper(['9999 aaa\\n', '19998 bbb\\n', '29997 ccc\\n']))
    '9999\\t19998\\taaa\\n19998\\t29997\\tbbb'
    """
    for couple_lines in itertools.pairwise(lines):
        current, next = couple_lines
        current_start, *ret = current.split()
        next_start, *_ = next.split()
        # print(current_start)
        yield "\t".join([current_start, next_start, *ret])


def main():
    lines = sys.stdin.readlines()
    print("\n".join(readlines_wrapper(lines)))


if __name__ == "__main__":
    import doctest
    doctest.testmod()
    main()
