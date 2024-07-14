#!/usr/bin/env python3

import sys


def main():
    lines = sys.stdin.readlines()

    for couple_lines in zip(lines, lines[1::]):
        current, next = couple_lines
        current_start, *ret = current.split()
        next_start, *_ = next.split()

        # print(current_start)
        print(*[current_start, next_start, *ret], sep="\t")


if __name__ == "__main__":
    main()
