# Standard library
import itertools
import random
import secrets
import re

from collections import defaultdict
from datetime import datetime, timedelta, timezone
from importlib import reload
from itertools import combinations, permutations
from math import sin, cos, tan, pi, sqrt, exp
from pprint import pprint
from time import sleep
from typing import Optional, List, Dict, Union, Any

# PyPI packages
import requests

# Set up logging
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# Shorthands
req = requests
it = itertools
