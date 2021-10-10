# noqa: F401
# Standard library
import itertools
import random
import secrets
import re
import subprocess

from math import *
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from importlib import reload
from itertools import combinations, permutations
from pprint import pprint
from time import sleep
from typing import Optional, List, Dict, Union, Any
from pathlib import Path

# PyPI packages
import pandas as pd
import numpy as np
import scipy
import matplotlib.pyplot as plt
import requests

# Set up logging
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()

# Shorthands
req = requests
it = itertools
