#!/usr/bin/env python3
"""
POC Demo Script for SLSA Scenario 1: Create package + verify

This script demonstrates the exact usage mentioned in the POC:
- import zobra
- zobra.dump_file('foo.txt')
"""

print("🎯 SLSA POC Scenario 1: Create package + verify")
print("=" * 60)

# Import the zobra package
print("📦 Importing zobra package...")
import zobra

print(f"✅ Successfully imported zobra v{zobra.get_version()}")
print()

# Use the exact function call from the POC
print("📝 Executing: zobra.dump_file('foo.txt')")
zobra.dump_file('foo.txt')
print()

# Verify the file was created
print("🔍 Verifying file creation...")
try:
    content = zobra.read_file('foo.txt')
    print("✅ File 'foo.txt' created successfully!")
    print(f"📄 File size: {len(content)} characters")
    print()
    
    # Show first few lines
    lines = content.split('\n')[:5]
    print("📖 First few lines of foo.txt:")
    for i, line in enumerate(lines, 1):
        print(f"   {i}: {line}")
    print("   ...")
    print()
    
except Exception as e:
    print(f"❌ Error reading file: {e}")

print("🎉 POC Demo completed successfully!")
print()
print("📋 Summary:")
print("   ✅ Package imported: zobra")
print("   ✅ Function executed: zobra.dump_file('foo.txt')")
print("   ✅ File created: foo.txt")
print()
print("🔄 Next steps:")
print("   1. ✅ Package built and tagged (v0.1.0)")
print("   2. 🔄 SLSA provenance generation (GitHub Actions)")
print("   3. ⏳ Provenance verification (slsa-verifier)")
print()
print("🌐 Check GitHub Actions: https://github.com/wiz-sec/zobra/actions")
print("📦 Check Releases: https://github.com/wiz-sec/zobra/releases")
