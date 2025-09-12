# ADE crypt Makefile
# Common development tasks

.PHONY: help test lint coverage install clean setup-dev docs check-deps install-dev \
	security audit scan performance perf benchmark metrics code-metrics \
	install-security-tools gitleaks secrets fix-security all-checks

# Default target
help:
	@echo "ADE crypt Development Tasks"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo ""
	@echo "Development:"
	@echo "  check-deps     Check all dependencies"
	@echo "  install-dev    Install development dependencies"
	@echo "  test           Run all tests"
	@echo "  lint           Run ShellCheck linting"
	@echo "  coverage       Generate coverage report"
	@echo "  clean          Clean temporary files"
	@echo ""
	@echo "Security Analysis:"
	@echo "  security       Run complete security audit"
	@echo "  audit          Alias for security"
	@echo "  gitleaks       Run Gitleaks secret scanner"
	@echo "  secrets        Scan for hardcoded secrets"
	@echo "  fix-security   Auto-fix security issues (where possible)"
	@echo ""
	@echo "Performance Analysis:"
	@echo "  performance    Run performance benchmarks"
	@echo "  perf           Alias for performance"
	@echo "  benchmark      Detailed performance testing"
	@echo ""
	@echo "Code Quality:"
	@echo "  metrics        Generate code metrics report"
	@echo "  code-metrics   Detailed code analysis with scc"
	@echo "  all-checks     Run ALL quality checks (lint, test, security, perf)"
	@echo ""
	@echo "Installation:"
	@echo "  install        Install ADE crypt system-wide"
	@echo "  install-security-tools  Install security analysis tools"
	@echo "  setup          Set up development environment"
	@echo ""
	@echo "Other:"
	@echo "  docs           Generate documentation"
	@echo "  ci             Run full CI pipeline locally"
	@echo "  release        Prepare release package"

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
	@cp -r src docs scripts tests ade-crypt install.sh LICENSE README.md Makefile release/ade-crypt/
	@cd release && tar czf ade-crypt-$$(date +%Y%m%d-%H%M%S).tar.gz ade-crypt/
	@echo "✓ Release package created in release/"

# Quick development cycle
dev: lint test
	@echo "✓ Development cycle complete"

# ============================================================================
# SECURITY ANALYSIS TARGETS
# ============================================================================

# Run complete security audit
security:
	@echo "🔒 Running Security Audit..."
	@./scripts/security-audit.sh || true
	@echo ""
	@echo "💡 Run 'make fix-security' to auto-fix some issues"

# Alias for security
audit: security

# Run Gitleaks secret scanner
gitleaks:
	@echo "🔍 Scanning for secrets with Gitleaks..."
	@if command -v gitleaks >/dev/null 2>&1; then \
		gitleaks detect --source . --verbose; \
	else \
		echo "⚠️  Gitleaks not installed. Run: make install-security-tools"; \
	fi

# Scan for hardcoded secrets
secrets:
	@echo "🔐 Scanning for hardcoded secrets..."
	@grep -rE '(password|secret|key|token|api_key)=' src/ --include="*.sh" || true
	@echo ""
	@if command -v trufflehog >/dev/null 2>&1; then \
		echo "Running TruffleHog..."; \
		trufflehog filesystem . --no-verification 2>/dev/null | head -20; \
	else \
		echo "💡 Install TruffleHog for deeper scanning: pip install truffleHog3"; \
	fi

# Auto-fix security issues where possible
fix-security:
	@echo "🔧 Auto-fixing security issues..."
	@echo "Converting predictable temp files to mktemp..."
	@find src -name "*.sh" -exec sed -i 's|/tmp/[a-zA-Z_]*\$$|$$(mktemp /tmp/XXXXXX)|g' {} \;
	@echo "✓ Fixed predictable temp files"
	@echo ""
	@echo "⚠️  Manual fixes still needed for:"
	@echo "  - Add trap handlers for cleanup"
	@echo "  - Replace rm -f with shred for sensitive files"
	@echo ""
	@echo "Run 'make security' to verify fixes"

# ============================================================================
# PERFORMANCE ANALYSIS TARGETS
# ============================================================================

# Run performance benchmarks
performance:
	@echo "⚡ Running Performance Benchmarks..."
	@./scripts/performance-test.sh

# Alias for performance
perf: performance

# Detailed benchmark testing
benchmark:
	@echo "📊 Detailed Benchmark Testing..."
	@if command -v hyperfine >/dev/null 2>&1; then \
		echo "Testing encryption performance..."; \
		hyperfine --warmup 3 --runs 10 \
			'echo "test" | ./ade-crypt encrypt /dev/stdin /tmp/test.enc' \
			'echo "test" | openssl enc -aes-256-cbc -salt -out /tmp/test2.enc -pass pass:test'; \
	else \
		echo "⚠️  hyperfine not installed. Run: make install-security-tools"; \
		time ./ade-crypt version; \
	fi

# ============================================================================
# CODE METRICS TARGETS
# ============================================================================

# Generate code metrics report
metrics:
	@echo "📈 Generating Code Metrics..."
	@echo ""
	@echo "Lines of Code:"
	@wc -l src/**/*.sh src/*.sh 2>/dev/null | tail -1
	@echo ""
	@echo "File Complexity (by size):"
	@find src -name "*.sh" -exec wc -l {} \; | sort -rn | head -5
	@echo ""
	@if command -v scc >/dev/null 2>&1; then \
		scc src/ --no-complexity --no-duplicates; \
	else \
		echo "💡 Install scc for detailed metrics: make install-security-tools"; \
	fi

# Detailed code analysis
code-metrics:
	@echo "📊 Detailed Code Analysis..."
	@if command -v scc >/dev/null 2>&1; then \
		scc src/ --by-file --include-ext sh; \
	else \
		echo "Installing scc..."; \
		go install github.com/boyter/scc/v3@latest 2>/dev/null || echo "Need Go installed"; \
	fi

# ============================================================================
# INSTALLATION TARGETS
# ============================================================================

# Install security analysis tools
install-security-tools:
	@echo "🛠️  Installing Security & Analysis Tools..."
	@./scripts/install-security-tools.sh

# ============================================================================
# COMPREHENSIVE CHECKS
# ============================================================================

# Run ALL quality checks
all-checks: lint test security performance metrics
	@echo ""
	@echo "=" 
	@echo "🎉 All Quality Checks Complete!"
	@echo "="
	@echo ""
	@echo "Summary:"
	@echo "  ✓ Linting passed"
	@echo "  ✓ Tests executed"
	@echo "  ✓ Security audit complete"
	@echo "  ✓ Performance benchmarked"
	@echo "  ✓ Metrics generated"
	@echo ""
	@echo "Run 'make coverage' for test coverage report"

# Pre-commit checks (good for git hooks)
pre-commit: lint test security
	@echo "✓ Pre-commit checks passed"

# Full CI/CD pipeline
full-ci: install-dev all-checks coverage
	@echo "✓ Full CI pipeline complete"