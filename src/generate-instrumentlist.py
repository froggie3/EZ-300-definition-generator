#!/usr/bin/env python3

import argparse
import xml.etree.ElementTree as ET
from xml.dom import minidom
import sys

# マップデータの読み込み
def read_mapfile(filename):
    maps = []
    with open(filename, 'r', encoding='utf-8') as file:
        for line in file:
            parts = line.strip().split('\t')
            maps.append((int(parts[0]), parts[1], parts[2]))
    return maps

# 要素データの読み込み
def read_elements(filename):
    elements = []
    with open(filename, 'r', encoding='utf-8') as file:
        for line in file:
            parts = line.strip().split()
            index = int(parts[0])
            lsb = int(parts[1])
            msb = int(parts[2])
            pc = int(parts[3])
            pc_name = parts[4]
            bank_name = parts[5]
            elements.append((index, lsb, msb, pc, pc_name, bank_name))
    return elements

# マップと要素をXMLに変換
def create_xml(maps, elements):
    root = ET.Element("InstrumentList")

    for map_start, map_jp, map_en in maps:
        map_elem = ET.SubElement(root, "Map", Name=map_jp)

        for elem in elements:
            index, lsb, msb, pc, pc_name, bank_name = elem
            if map_start <= index < map_start + 7:
                pc_elem = None
                for child in map_elem:
                    if child.attrib['PC'] == str(pc):
                        pc_elem = child
                        break
                
                if not pc_elem:
                    pc_elem = ET.SubElement(map_elem, "PC", Name=pc_name.replace("_", " "), PC=str(pc))
                
                ET.SubElement(pc_elem, "Bank", Name=bank_name.replace("_", " "), MSB=str(msb), LSB=str(lsb))

    return root

# XMLを整形して標準出力に出力
def print_xml(root):
    rough_string = ET.tostring(root, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    pretty_string = reparsed.toprettyxml(indent="    ")
    print(pretty_string)

# メイン処理
def main():
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
