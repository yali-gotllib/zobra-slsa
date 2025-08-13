"""
Tests for the zobra package.
"""

import os
import tempfile
import pytest
from pathlib import Path

import zobra


class TestZobra:
    """Test cases for zobra package functionality."""
    
    def test_dump_file_default_content(self):
        """Test dump_file with default content."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = Path(tmpdir) / "test_file.txt"
            
            zobra.dump_file(str(filepath))
            
            assert filepath.exists()
            content = filepath.read_text(encoding='utf-8')
            assert "File created by zobra package" in content
            assert "test_file.txt" in content
            assert "zobra v0.1.0" in content
    
    def test_dump_file_custom_content(self):
        """Test dump_file with custom content."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = Path(tmpdir) / "custom_file.txt"
            custom_content = "Hello, SLSA world!"
            
            zobra.dump_file(str(filepath), custom_content)
            
            assert filepath.exists()
            content = filepath.read_text(encoding='utf-8')
            assert content == custom_content
    
    def test_dump_file_creates_directories(self):
        """Test that dump_file creates parent directories."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = Path(tmpdir) / "subdir" / "nested" / "file.txt"
            
            zobra.dump_file(str(filepath), "test content")
            
            assert filepath.exists()
            assert filepath.read_text(encoding='utf-8') == "test content"
    
    def test_read_file(self):
        """Test read_file functionality."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = Path(tmpdir) / "read_test.txt"
            test_content = "This is test content for reading"
            
            # Create file first
            zobra.dump_file(str(filepath), test_content)
            
            # Read it back
            read_content = zobra.read_file(str(filepath))
            assert read_content == test_content
    
    def test_read_file_not_found(self):
        """Test read_file with non-existent file."""
        with pytest.raises(FileNotFoundError):
            zobra.read_file("non_existent_file.txt")
    
    def test_get_version(self):
        """Test get_version returns correct version."""
        version = zobra.get_version()
        assert version == "0.1.0"
    
    def test_package_imports(self):
        """Test that all expected functions are importable."""
        # Test direct import
        from zobra import dump_file, read_file, get_version
        
        # Test they are callable
        assert callable(dump_file)
        assert callable(read_file)
        assert callable(get_version)
    
    def test_dump_file_with_pathlib(self):
        """Test dump_file works with pathlib.Path objects."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = Path(tmpdir) / "pathlib_test.txt"
            
            zobra.dump_file(filepath, "pathlib test")
            
            assert filepath.exists()
            assert filepath.read_text(encoding='utf-8') == "pathlib test"
