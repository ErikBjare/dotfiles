# Standard library
import itertools
import random
import secrets
import re

from math import *
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from importlib import reload
from itertools import combinations, permutations
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
