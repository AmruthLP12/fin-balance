FLUTTER := /snap/bin/flutter
DART := /snap/bin/dart

.PHONY: help get analyze format test run build-debug build-release clean

help:
	@echo "FinBalance Development Commands:"
	@echo "  make get           - Install dependencies"
	@echo "  make analyze       - Run static analysis"
	@echo "  make format        - Format Dart source files"
	@echo "  make test          - Run all automated tests"
	@echo "  make run           - Run the application"
	@echo "  make build-debug   - Build Android debug APK"
	@echo "  make build-release - Build Android release APK"
	@echo "  make clean         - Clean Flutter build artifacts"

get:
	$(FLUTTER) pub get

analyze:
	$(FLUTTER) analyze

format:
	$(DART) format --set-exit-if-changed lib test

test:
	$(FLUTTER) test

run:
	$(FLUTTER) run

build-debug:
	$(FLUTTER) build apk --debug

build-release:
	$(FLUTTER) build apk --release

clean:
	$(FLUTTER) clean
