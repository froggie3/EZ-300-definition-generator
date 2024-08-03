#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree as ET

from library.common import debug_print, print_pretty_xml


def read_mapfile(file):
    """マップデータの読み込み"""
    maps = []
    for parts in (line.strip().split('\t') for line in file):
        maps.append((int(parts[0]), int(parts[1]), parts[2], parts[3]))
    return maps


def read_elements(file):
    """要素データの読み込み"""
    elements = []
    for parts in (line.strip().split() for line in file):
        index = int(parts[0])
        msb = int(parts[1])
        lsb = int(parts[2])
        pc = int(parts[3])
        bank_name_en = parts[4].replace("_", " ")
        bank_name_ja = parts[5].replace("_", " ")
        elements.append((index, msb, lsb, pc, bank_name_en, bank_name_ja))
    return elements


def create_xml(maps, elements):
    """マップと要素をXMLに変換"""
    root = ET.Element("InstrumentList")

    # To-do: 余裕があれば効率化 & PC 周りの前処理
    for map_start, map_end, map_jp, map_en in maps:
        map_elem = ET.SubElement(root, "Map", Name=map_jp)

        for elem in elements:
            index, msb, lsb, pc, bank_name_en, bank_name_ja = elem
            if map_start <= index < map_end:
                pc_elem = None
                for child in map_elem:
                    if child.attrib['PC'] == str(pc):
                        pc_elem = child
                        break

                if not pc_elem:
                    pc_elem = ET.SubElement(
                        map_elem, "PC", Name=bank_name_ja, PC=str(pc)
                    )

                ET.SubElement(
                    pc_elem, "Bank", Name=bank_name_en, MSB=str(msb), LSB=str(lsb)
                )

    return root


def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(description='Mapと要素のデータからXMLを生成します。')
    parser.add_argument('mapfile', type=argparse.FileType(), help='マップファイルのパス')
    parser.add_argument(
        'elementsfile', type=argparse.FileType(), help='要素ファイルのパス')
    args = parser.parse_args()
    debug_print(args)

    maps = read_mapfile(args.mapfile)
    elements = read_elements(args.elementsfile)
    xml_root = create_xml(maps, elements)
    print_pretty_xml(xml_root)


if __name__ == '__main__':
    main()
