"""
Zobra - A simple Python package for SLSA provenance demonstration.

This package provides basic file operations for demonstrating SLSA 
(Supply-chain Levels for Software Artifacts) provenance generation and verification.
"""

__version__ = "0.1.0"
__author__ = "Wiz Security"
__email__ = "security@wiz.io"

from .core import dump_file, read_file, get_version

__all__ = [
    "dump_file",
    "read_file", 
    "get_version",
]
