import sys
import xml.etree.ElementTree as ET
from xml.dom import minidom


def print_pretty_xml(root):
    """XMLを整形して標準出力に出力"""
    rough_string = ET.tostring(root, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    pretty_string = reparsed.toprettyxml(
        indent="    "
    )
    print(
        pretty_string,
        file=sys.stdout  # sys.stderr
    )

def print_xml(root):
    rough_string = ET.tostring(root, 'utf-8').decode()
    print(
        rough_string,
        file=sys.stdout  # sys.stderr
    )



# 音が出ないノート
MASK_STRING = "__MUTE__"