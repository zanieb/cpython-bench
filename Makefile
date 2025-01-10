# Directories
CPYTHON_DIR := ../cpython
OUT_DIR := out

# Build settings
JOBS := 12
COMMON_CONFIG := py_cv_module__openssl=n/a py_cv_module__hashlib=n/a py_cv_module__gdbm=n/a --without-ensurepip --enable-optimizations --with-bolt

# Python variants to build (add more as needed)
VARIANTS := bolt-baseline bolt-cdsplit bolt-hugify bolt-split-all-cold

# Generate paths for each variant
PYTHON_BINS := $(foreach v,$(VARIANTS),$(OUT_DIR)/$(v)/bin/python3)
BENCH_JSONS := $(foreach v,$(VARIANTS),$(OUT_DIR)/$(v).json)

#Extra flags for pyperformance (e.g. BENCH_FLAGS="--fast")
BENCH_FLAGS ?=


.PHONY: all clean

all: $(BENCH_JSONS)

# Create output directory
$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# Rule for benchmark JSON files
$(OUT_DIR)/%.json: $(OUT_DIR)/%/bin/python3
	cd $(CPYTHON_DIR) && \
	LD_LIBRARY_PATH=$(CURDIR)/$(OUT_DIR)/$*/lib \
	uvx pyperformance run \
		--python=$(CURDIR)/$< \
		-o $(CURDIR)/$@ \
		$(BENCH_FLAGS) \
		--inherit-environ LD_LIBRARY_PATH

# Rule for building Python
$(OUT_DIR)/%/bin/python3: $(CPYTHON_DIR)/.git/HEAD $(OUT_DIR)
	git -C $(CPYTHON_DIR) checkout $(notdir $*)
	$(MAKE) -C $(CPYTHON_DIR) clean
	cd $(CPYTHON_DIR) && ./configure $(COMMON_CONFIG) --prefix=$(CURDIR)/$(OUT_DIR)/$(notdir $*)
	$(MAKE) -C $(CPYTHON_DIR) -j$(JOBS)
	$(MAKE) -C $(CPYTHON_DIR) install

# Clean all build artifacts and benchmarks
clean:
	rm -rf $(OUT_DIR)

# Show configured variants
list-variants:
	@echo "Configured variants: $(VARIANTS)"
	@echo "Python binaries: $(PYTHON_BINS)"
	@echo "Benchmark files: $(BENCH_JSONS)"
