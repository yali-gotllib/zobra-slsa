#!/usr/bin/env python3
"""
Example usage of the zobra package.

This script demonstrates the basic functionality of zobra
for SLSA provenance demonstration purposes.
"""

import zobra


def main():
    """Demonstrate zobra package functionality."""
    print("🔧 Zobra Package Demo")
    print("=" * 50)
    
    # Show package version
    version = zobra.get_version()
    print(f"📦 Zobra version: {version}")
    print()
    
    # Create a file with default content
    print("📝 Creating 'foo.txt' with default content...")
    zobra.dump_file('foo.txt')
    print()
    
    # Create a file with custom content
    print("📝 Creating 'custom.txt' with custom content...")
    custom_content = """Hello from Zobra!

This is a custom file created for SLSA demonstration.
It shows how zobra can create files with specific content.

SLSA helps secure the software supply chain by providing
provenance information about how software artifacts were built.
"""
    zobra.dump_file('custom.txt', custom_content)
    print()
    
    # Read back the files
    print("📖 Reading back the created files:")
    print()
    
    print("--- Contents of foo.txt ---")
    foo_content = zobra.read_file('foo.txt')
    print(foo_content[:200] + "..." if len(foo_content) > 200 else foo_content)
    print()
    
    print("--- Contents of custom.txt ---")
    custom_read = zobra.read_file('custom.txt')
    print(custom_read)
    print()
    
    print("✅ Demo completed successfully!")
    print("Files created: foo.txt, custom.txt")
    print("Ready for SLSA provenance generation and verification!")


if __name__ == "__main__":
    main()
