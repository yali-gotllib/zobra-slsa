"""
Core functionality for the zobra package.
"""

import os
import datetime
from typing import Optional, Union
from pathlib import Path


def dump_file(filename: Union[str, Path], content: Optional[str] = None) -> None:
    """
    Create a file with optional content.
    
    If no content is provided, creates a file with a default message
    including timestamp and package information.
    
    Args:
        filename: Path to the file to create
        content: Optional content to write to the file. If None, 
                uses default content with timestamp.
    
    Raises:
        OSError: If the file cannot be created or written to
        PermissionError: If insufficient permissions to create the file
    """
    filepath = Path(filename)
    
    if content is None:
        content = _generate_default_content(filepath.name)
    
    try:
        # Create parent directories if they don't exist
        filepath.parent.mkdir(parents=True, exist_ok=True)
        
        # Write content to file
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
            
        print(f"✅ File '{filename}' created successfully")
        
    except PermissionError as e:
        raise PermissionError(f"Permission denied: Cannot create file '{filename}'") from e
    except OSError as e:
        raise OSError(f"Failed to create file '{filename}': {e}") from e


def read_file(filename: Union[str, Path]) -> str:
    """
    Read content from a file.
    
    Args:
        filename: Path to the file to read
        
    Returns:
        str: Content of the file
        
    Raises:
        FileNotFoundError: If the file doesn't exist
        OSError: If the file cannot be read
    """
    filepath = Path(filename)
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError as e:
        raise FileNotFoundError(f"File not found: '{filename}'") from e
    except OSError as e:
        raise OSError(f"Failed to read file '{filename}': {e}") from e


def get_version() -> str:
    """
    Get the current version of the zobra package.
    
    Returns:
        str: Version string
    """
    from . import __version__
    return __version__


def _generate_default_content(filename: str) -> str:
    """
    Generate default content for a file.
    
    Args:
        filename: Name of the file being created
        
    Returns:
        str: Default content with timestamp and package info
    """
    timestamp = datetime.datetime.now().isoformat()
    
    content = f"""# File created by zobra package
# Filename: {filename}
# Created: {timestamp}
# Package: zobra v{get_version()}
# Purpose: SLSA provenance demonstration

This file was created by the zobra Python package as part of a 
Supply-chain Levels for Software Artifacts (SLSA) demonstration.

Zobra is a simple package designed to showcase:
- Package creation and distribution
- SLSA provenance generation
- Provenance verification workflows

For more information about SLSA, visit: https://slsa.dev/

Generated at: {timestamp}
"""
    
    return content
