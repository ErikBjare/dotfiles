# Standard library
import re
import itertools
from math import pi
from time import sleep
from pprint import pprint
from typing import Optional, List, Dict, Union, Any
from importlib import reload
from datetime import datetime, timezone
from collections import defaultdict

# PyPI packages
import requests

# Set up logging
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# Shorthands
req = requests
it = itertools
