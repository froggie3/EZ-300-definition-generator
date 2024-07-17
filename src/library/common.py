import sys
import xml.etree.ElementTree as ET
from xml.dom import minidom
import functools


def print_xml(root):
    """XMLを整形して標準出力に出力"""
    rough_string = ET.tostring(root, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    pretty_string = reparsed.toprettyxml(
        # indent="    "
    )
    print(
        pretty_string,
        file=sys.stdout  # sys.stderr
    )


# 音が出ないノート
MASK_STRING = "__MUTE__"
