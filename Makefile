# ADE crypt Makefile
# Common development tasks

.PHONY: help test lint coverage install clean setup-dev docs check-deps install-dev

# Default target
help:
	@echo "ADE crypt Development Tasks"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  check-deps  Check all dependencies"
	@echo "  install-dev Install development dependencies"
	@echo "  test        Run all tests"
	@echo "  lint        Run ShellCheck linting"
	@echo "  coverage    Generate coverage report"
	@echo "  install     Install ADE crypt system-wide"
	@echo "  clean       Clean temporary files"
	@echo "  setup       Set up development environment"
	@echo "  docs        Generate documentation"
	@echo "  ci          Run full CI pipeline locally"
	@echo "  release     Prepare release package"

# Run tests
test:
	@echo "Running tests..."
	./scripts/test.sh

# Run linting
lint:
	@echo "Running ShellCheck..."
	./scripts/lint.sh

# Generate coverage report
coverage:
	@echo "Generating coverage report..."
	./scripts/coverage.sh

# Check dependencies
check-deps:
	@echo "Checking dependencies..."
	./scripts/check-deps.sh

# Check development dependencies
check-dev-deps:
	@echo "Checking development dependencies..."
	./scripts/check-deps.sh --dev

# Install development dependencies
install-dev:
	@echo "Installing development dependencies..."
	./scripts/install-dev-deps.sh

# Install system-wide
install:
	@echo "Installing ADE crypt..."
	./install.sh

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	rm -rf /tmp/ade-crypt-test-*
	rm -rf coverage/
	rm -rf test-results/
	find . -name "*.tmp" -delete
	find . -name "*.enc" -not -path "./tests/*" -delete

# Set up development environment
setup: check-deps check-dev-deps
	@echo "Setting up development environment..."
	@# Install pre-commit if available
	@if command -v pip >/dev/null 2>&1; then \
		pip install pre-commit; \
		pre-commit install; \
		echo "✓ Pre-commit hooks installed"; \
	else \
		echo "⚠ pip not found, skipping pre-commit setup"; \
	fi
	@echo "✓ Development environment ready"

# Legacy alias for setup
setup-dev: setup

# Generate documentation
docs:
	@echo "Generating documentation..."
	@# This could integrate with tools like GitBook, MkDocs, etc.
	@echo "Documentation is in docs/ directory"
	@ls -la docs/

# Run full CI pipeline locally
ci: lint test
	@echo "Running integration tests..."
	@./ade-crypt version
	@./ade-crypt help > /dev/null
	@echo "✓ Basic integration tests passed"

# Prepare release package  
release:
	@echo "Preparing release package..."
	@mkdir -p release/ade-crypt
	@cp -r bin src docs ade-crypt install.sh LICENSE README.md release/ade-crypt/
	@cd release && tar czf ade-crypt-$$(date +%Y%m%d-%H%M%S).tar.gz ade-crypt/
	@echo "✓ Release package created in release/"

# Quick development cycle
dev: lint test
	@echo "✓ Development cycle complete"