# Directories
CPYTHON_DIR ?= ../cpython
OUT_DIR := out

# Build settings
CPYTHON_BUILD_JOBS ?= 12
CPYTHON_BUILD_ARGS ?= py_cv_module__openssl=n/a py_cv_module__hashlib=n/a py_cv_module__gdbm=n/a --without-ensurepip --enable-optimizations --enable-bolt

# CPython references to bench, branches or commits
CPYTHON_BENCH_REFS ?= bolt-baseline bolt-cdsplit bolt-hugify bolt-split-all-cold

# Generate paths for each variant
PYTHON_BINS := $(foreach v,$(CPYTHON_BENCH_REFS),$(OUT_DIR)/$(v)/bin/python3)
BENCH_JSONS := $(foreach v,$(CPYTHON_BENCH_REFS),$(OUT_DIR)/$(v).json)

# Extra flags for pyperformance (e.g. BENCH_RUN_ARGS="--fast")
BENCH_RUN_ARGS ?=

.PHONY: all clean

# Prevent deletion of Python binaries, they're expensive to build
.SECONDARY: $(PYTHON_BINS)

all: $(BENCH_JSONS)

$(OUT_DIR):
	mkdir -p $(OUT_DIR)

# Benchmarking with `pyperformance`
# Note we only run the subset of benchmarks which succeed on Python 3.14
$(OUT_DIR)/%.json: $(OUT_DIR)/%/bin/python3
	cd $(CPYTHON_DIR) && \
	LD_LIBRARY_PATH=$(CURDIR)/$(OUT_DIR)/$*/lib \
	uvx pyperformance run \
		--python=$(CURDIR)/$< \
		-o $(CURDIR)/$@ \
		$(BENCH_RUN_ARGS) \
		--inherit-environ LD_LIBRARY_PATH \
		--benchmarks \
		"2to3, \
		async_generators, \
		asyncio_tcp, \
		asyncio_tcp_ssl, \
		asyncio_websockets, \
		chaos, \
		comprehensions, \
		concurrent_imap, \
		coroutines, \
		coverage, \
		crypto_pyaes, \
		deepcopy, \
		deltablue, \
		docutils, \
		dulwich_log, \
		fannkuch, \
		float, \
		gc_collect, \
		gc_traversal, \
		generators, \
		genshi, \
		go, \
		hexiom, \
		html5lib, \
		json_dumps, \
		json_loads, \
		logging, \
		mako, \
		mdp, \
		meteor_contest, \
		nbody, \
		nqueens, \
		pathlib, \
		pickle, \
		pickle_dict, \
		pickle_list, \
		pickle_pure_python, \
		pidigits, \
		pprint, \
		pyflate, \
		python_startup, \
		python_startup_no_site, \
		raytrace, \
		regex_compile, \
		regex_dna, \
		regex_effbot, \
		regex_v8, \
		richards, \
		richards_super, \
		scimark, \
		spectral_norm, \
		sqlglot, \
		sqlite_synth, \
		telco, \
		tomli_loads, \
		typing_runtime_protocols, \
		unpack_sequence, \
		unpickle, \
		unpickle_list, \
		unpickle_pure_python, \
		xml_etree"

# Build CPython with the target branch and install to `out`
$(OUT_DIR)/%/bin/python3: | $(OUT_DIR)
	git -C $(CPYTHON_DIR) checkout $(notdir $*)
	$(MAKE) -C $(CPYTHON_DIR) clean
	cd $(CPYTHON_DIR) && ./configure $(CPYTHON_BUILD_ARGS) --prefix=$(CURDIR)/$(OUT_DIR)/$(notdir $*)
	$(MAKE) -C $(CPYTHON_DIR) -j$(CPYTHON_BUILD_JOBS)
	$(MAKE) -C $(CPYTHON_DIR) install

# Clean all build artifacts and benchmarks
clean:
	rm -rf $(OUT_DIR)

# Show configured variants
list:
	@echo "Configured variants: $(CPYTHON_BENCH_REFS)"
	@echo "Python binaries: $(PYTHON_BINS)"
	@echo "Benchmark files: $(BENCH_JSONS)"
