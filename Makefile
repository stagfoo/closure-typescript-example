.DEFAULT_GOAL := run

all: js

define HELP_TEXT
all          -   js
js           -   compile all js
ts           -   compile all ts
deps         -   locally install all dependencies
run          -   compile and execute main.js

clean-*      -   remove files created by target *
help         -   print this message
endef
export HELP_TEXT

.PHONY: help
help:
	$(info $(HELP_TEXT))

UNAME_S := $(shell uname -s)

LEFT_PAREN := (
RIGHT_PAREN := )

# js
JS_ROOT := js/app
TS_OUTPUT_DIR := $(JS_ROOT)/ts
JS_BIN_PATH := js/bin
JS_EXTERNS_ROOT := js/externs
JS_CLOSURE_LIBRARY_ROOTS := js/closure-library/closure/goog

JS_SOURCES = $(shell find $(JS_ROOT) -type f -name '*.js')
JS_SOURCES_NO_TS = $(sort \
	$(shell find $(JS_ROOT) \
		-not -path "$(TS_OUTPUT_DIR)/*" \
		-type f \
		-name "*.js" \
	) \
)
JS_CLOSURE_LIBRARY_SOURCES = $(sort \
	$(shell find $(JS_CLOSURE_LIBRARY_ROOTS) \
		-not -name "*_test.js" \
		-type f \
		-name "*.js" \
	) \
)
JS_EXTERNS = $(shell find $(JS_EXTERNS_ROOT) -type f -name '*.js')

js: $(JS_BIN_PATH)/main.js
$(JS_BIN_PATH)/main.js: $(JS_SOURCES) $(JS_EXTERNS) ts build/.closure-compiler
	mkdir -p $(JS_BIN_PATH)
	$(CLOSURE_COMPILE) \
		$(JS_EXTERNS:%=--externs %) \
		--externs $(TS_EXTERNS_PATH) \
		--js_output_file $(JS_BIN_PATH)/main.js \
		--closure_entry_point "main" \
		$(JS_ROOT:%='%/**.js')

clean-js:
	rm -rf $(JS_BIN_PATH)

# ts
TS_ROOT := ts/app
TS_DEFINITIONS_ROOT := $(TS_ROOT)/definitions
TS_SOURCES := $(shell find $(TS_ROOT) -type f -name '*.ts')
TS_EXTERNS_PATH := js/tsickle_externs.js

# TypeScript compiler options are in ts/tsconfig.json
ts: build/.ts-output
build/.ts-output: build/.npm-install build/.tsickle $(TS_SOURCES) clutz
	mkdir -p $(TS_OUTPUT_DIR)
	$(TSICKLE) --externs=$(TS_EXTERNS_PATH) -- --project $(TS_ROOT)
	@> $@

clean-ts:
	rm -rf build/.ts-output $(TS_EXTERNS_PATH) $(TS_OUTPUT_DIR)

clean: clean-deps \
	clean-js \
	clean-ts

# external makefiles
include build/deps.makefile

run: js
	$(NODE) $(JS_BIN_PATH)/main.js