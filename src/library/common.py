import sys
import xml.etree.ElementTree as ET
from pprint import pprint
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
        file=sys.stdout,  # sys.stderr
        end=""
    )


def print_xml(root):
    rough_string = ET.tostring(root, 'utf-8').decode()
    print(
        rough_string,
        file=sys.stdout,  # sys.stderr
        end=""
    )


def get_key_name_debug(iter):
    for key, name in map(lambda x: x.strip().split("\t"), iter):
        debug_print(key, name)
        yield key, name


def debug_print(*obj):
    # pprint(*obj, stream=sys.stderr)
    pass


# 音が出ないノート
MASK_STRING = "__MUTE__"
