#!/usr/bin/env python3
"""
Convert GitHub attestations to SLSA provenance format for use with slsa-verifier.

This script extracts the SLSA provenance from GitHub's Sigstore bundle format
and converts it to the standard in-toto JSONL format expected by slsa-verifier.
"""

import json
import base64
import sys
import argparse
from pathlib import Path


def extract_provenance_from_github_attestation(attestation_file: Path, output_file: Path):
    """
    Extract SLSA provenance from GitHub attestation bundle.

    Args:
        attestation_file: Path to GitHub attestation file (.jsonl)
        output_file: Path to output SLSA provenance file (.intoto.jsonl)
    """
    try:
        with open(attestation_file, 'r') as f:
            # GitHub attestations are in JSONL format, read first line
            attestation_data = json.loads(f.readline().strip())

        # Extract the DSSE envelope from the Sigstore bundle
        dsse_envelope = attestation_data.get('dsseEnvelope', {})

        if not dsse_envelope:
            raise ValueError("No DSSE envelope found in attestation")

        # Decode the base64-encoded payload
        payload_b64 = dsse_envelope.get('payload', '')
        if not payload_b64:
            raise ValueError("No payload found in DSSE envelope")

        # Decode the payload to get the in-toto statement
        payload_json = base64.b64decode(payload_b64).decode('utf-8')
        statement = json.loads(payload_json)

        # Verify this is a SLSA provenance statement
        if statement.get('predicateType') != 'https://slsa.dev/provenance/v1':
            raise ValueError(f"Not a SLSA provenance statement: {statement.get('predicateType')}")

        # Extract certificate from verification material
        verification_material = attestation_data.get('verificationMaterial', {})
        certificate = verification_material.get('certificate', {})
        cert_raw_bytes = certificate.get('rawBytes', '')

        if cert_raw_bytes:
            # Decode the certificate and format as PEM
            cert_bytes = base64.b64decode(cert_raw_bytes)
            cert_pem = base64.b64encode(cert_bytes).decode('ascii')

            # Format as proper PEM certificate
            cert_pem_formatted = '-----BEGIN CERTIFICATE-----\n'
            # Split into 64-character lines
            for i in range(0, len(cert_pem), 64):
                cert_pem_formatted += cert_pem[i:i+64] + '\n'
            cert_pem_formatted += '-----END CERTIFICATE-----'

            # Save certificate to separate file for verification
            cert_file = output_file.with_suffix('.crt')
            with open(cert_file, 'w') as f:
                f.write(cert_pem_formatted)
            print(f"   Certificate saved to: {cert_file}")

        # Create multiple output formats for different verifiers

        # Format 1: Standard DSSE envelope (what we had before)
        dsse_format = {
            "payload": payload_b64,
            "payloadType": dsse_envelope.get('payloadType', 'application/vnd.in-toto+json'),
            "signatures": dsse_envelope.get('signatures', [])
        }

        # Format 2: Plain SLSA provenance (for some verifiers)
        plain_format = statement

        # Format 3: Full Sigstore bundle (preserving all verification material)
        bundle_format = {
            "mediaType": "application/vnd.dev.sigstore.bundle.v0.3+json",
            "verificationMaterial": verification_material,
            "dsseEnvelope": dsse_envelope
        }

        # Write the DSSE format (primary output)
        with open(output_file, 'w') as f:
            json.dump(dsse_format, f, separators=(',', ':'))
            f.write('\n')

        # Write alternative formats
        plain_file = output_file.with_suffix('.slsa.json')
        with open(plain_file, 'w') as f:
            json.dump(plain_format, f, indent=2)

        bundle_file = output_file.with_suffix('.bundle.json')
        with open(bundle_file, 'w') as f:
            json.dump(bundle_format, f, indent=2)

        print(f"✅ Successfully converted attestation to multiple SLSA formats")
        print(f"   Input:  {attestation_file}")
        print(f"   DSSE:   {output_file}")
        print(f"   Plain:  {plain_file}")
        print(f"   Bundle: {bundle_file}")

        # Display some information about the provenance
        print(f"\n📋 Provenance Information:")
        print(f"   Predicate Type: {statement.get('predicateType')}")
        print(f"   Subjects: {len(statement.get('subject', []))}")

        for i, subject in enumerate(statement.get('subject', []), 1):
            print(f"     {i}. {subject.get('name', 'Unknown')}")

        builder_id = statement.get('predicate', {}).get('runDetails', {}).get('builder', {}).get('id', 'Unknown')
        print(f"   Builder ID: {builder_id}")

        return True

    except Exception as e:
        print(f"❌ Error converting attestation: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Convert GitHub attestations to SLSA provenance format for slsa-verifier"
    )
    parser.add_argument(
        'attestation_file',
        type=Path,
        help='Path to GitHub attestation file (.jsonl)'
    )
    parser.add_argument(
        '-o', '--output',
        type=Path,
        help='Output file path (default: <input>.intoto.jsonl)'
    )
    
    args = parser.parse_args()
    
    if not args.attestation_file.exists():
        print(f"❌ Attestation file not found: {args.attestation_file}")
        sys.exit(1)
    
    # Determine output file
    if args.output:
        output_file = args.output
    else:
        output_file = args.attestation_file.with_suffix('.intoto.jsonl')
    
    print(f"🔄 Converting GitHub attestation to SLSA provenance format...")
    
    success = extract_provenance_from_github_attestation(args.attestation_file, output_file)
    
    if success:
        print(f"\n🔍 Next steps:")
        print(f"   Use slsa-verifier to verify the converted provenance:")
        print(f"   slsa-verifier verify-artifact <artifacts> \\")
        print(f"     --provenance-path {output_file} \\")
        print(f"     --source-uri github.com/wiz-sec/zobra \\")
        print(f"     --source-tag v0.1.0")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
