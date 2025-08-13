package main

import (
	"fmt"
	"os"
	"time"
)

const version = "v1.0.0"

func main() {
	fmt.Printf("🎯 Zobra Go - SLSA Demonstration Package %s\n", version)
	fmt.Printf("📅 Built at: %s\n", time.Now().Format(time.RFC3339))
	fmt.Printf("🔒 This package demonstrates SLSA Level 3 provenance generation\n")
	fmt.Printf("✅ Generated using official SLSA Go builder\n")
	fmt.Printf("🛡️  Verified with slsa-verifier\n")
	
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "version":
			fmt.Printf("Version: %s\n", version)
		case "info":
			fmt.Println("Zobra Go is a demonstration package for SLSA provenance")
			fmt.Println("Features:")
			fmt.Println("- Official SLSA Level 3 provenance")
			fmt.Println("- Cryptographic attestation")
			fmt.Println("- Transparency log recording")
			fmt.Println("- Trusted by slsa-verifier")
		case "hello":
			name := "World"
			if len(os.Args) > 2 {
				name = os.Args[2]
			}
			fmt.Printf("Hello, %s! 👋\n", name)
		default:
			fmt.Printf("Unknown command: %s\n", os.Args[1])
			fmt.Println("Available commands: version, info, hello [name]")
		}
	} else {
		fmt.Println("\nUsage:")
		fmt.Println("  zobra-go version    - Show version")
		fmt.Println("  zobra-go info       - Show package info")
		fmt.Println("  zobra-go hello [name] - Say hello")
	}
}
