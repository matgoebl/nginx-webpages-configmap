#!/usr/bin/env python3
# Simple YAML preprocessor that includes other files using '!includefile FILENAME
# and substitutes variables like ${FOOBAR} from the environment.

import yaml
import sys
import string
import os

class Loader(yaml.SafeLoader):
    def includefile(self, node):
        filename = self.construct_scalar(node)
        with open(filename, 'r') as f:
            return f.read()

Loader.add_constructor('!includefile', Loader.includefile)

data = string.Template( sys.stdin.read() ).safe_substitute( os.environ )
print( yaml.dump_all( yaml.load_all(data, Loader) ) )
