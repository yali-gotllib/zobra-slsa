all:
	@echo "🏗️  Building C++ project..."
	mkdir -p build
	echo "Mock C++ binary - $$(date)" > build/myapp
	echo "Mock C++ library - $$(date)" > build/libmylib.so
	chmod +x build/myapp
	@echo "✅ Build complete!"
	@echo "Generated artifacts:"
	@ls -la build/

clean:
	rm -rf build/

.PHONY: all clean
