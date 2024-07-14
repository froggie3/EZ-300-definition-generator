#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree as ET
from xml.dom import minidom
import sys
from dataclasses import dataclass


def read_mapfile(filename):
    """マップデータの読み込み"""
    maps = []
    with open(filename, 'r', encoding='utf-8') as file:
        for line in file:
            parts = line.strip().split('\t')
            maps.append((int(parts[0]), int(parts[1]), parts[2], parts[3]))
    return maps


def read_elements(filename):
    """要素データの読み込み"""
    elements = []
    with open(filename, 'r', encoding='utf-8') as file:
        for line in file:
            parts = line.strip().split()
            index = int(parts[0])
            msb = int(parts[1])
            lsb = int(parts[2])
            pc = int(parts[3])
            bank_name_en = parts[4]
            bank_name_ja = parts[5]
            elements.append((index, msb, lsb, pc, bank_name_en, bank_name_ja))
    return elements


def create_xml(maps, elements):
    """マップと要素をXMLに変換"""
    root = ET.Element("InstrumentList")

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
                        map_elem, "PC", Name=bank_name_ja.replace("_", " "), PC=str(pc))

                ET.SubElement(pc_elem, "Bank", Name=bank_name_en.replace(
                    "_", " "), MSB=str(msb), LSB=str(lsb))

    return root


def print_xml(root):
    """XMLを整形して標準出力に出力"""
    rough_string = ET.tostring(root, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    pretty_string = reparsed.toprettyxml(indent="    ")
    print(pretty_string)


def main():
    """メイン処理"""
    parser = argparse.ArgumentParser(description='Mapと要素のデータからXMLを生成します。')
    parser.add_argument('mapfile', type=str, help='マップファイルのパス')
    parser.add_argument('elementsfile', type=str, help='要素ファイルのパス')
    args = parser.parse_args()

    maps = read_mapfile(args.mapfile)
    elements = read_elements(args.elementsfile)
    xml_root = create_xml(maps, elements)
    print_xml(xml_root)


if __name__ == '__main__':
    main()
