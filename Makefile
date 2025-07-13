MAELSTROM=./maelstrom/maelstrom
IMAGE_NAME=ds-course
CONTAINER_NAME=$(IMAGE_NAME)
CONTAINER_WRAP=docker build -t $(IMAGE_NAME) -f Dockerfile . && \
			   docker run -it --rm --name $(CONTAINER_NAME) $(IMAGE_NAME)
ENTER_TASK_DIR=cd $(TASK) &&
TASK_ENV=./$(TASK)/maelstrom.env

RUST_BUILD=cargo build --release
RUST_CLEAN=cargo clean
RUST_TARGET_PATH=./$(TASK)/target/release/$(TASK)

GO_BUILD=go build
GO_CLEAN=go clean
GO_TARGET_PATH=./$(TASK)/$(TASK)

GetCurrentBranch = $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: clean-wrapped
clean-wrapped:
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) $(RUST_CLEAN)
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) $(GO_CLEAN)
else
	@echo "Unsupported PROG_LANG env value: ${PROG_LANG}"
	exit 1
endif

.PHONY: build-wrapped
build-wrapped:
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) $(RUST_BUILD)
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) $(GO_BUILD)
endif


ifeq ($(PROG_LANG),rust)
TARGET_PATH := $(RUST_TARGET_PATH)
else ifeq ($(PROG_LANG),go)
TARGET_PATH := $(GO_TARGET_PATH)
endif
include $(TASK_ENV) # Include task-specific fault-injections
export # Activate fault-injections
.PHONY: run-wrapped
run-wrapped:
	$(MAELSTROM) test --bin $(TARGET_PATH) $(FAULT_INJECTIONS)

.PHONY: run-ci
run-ci:
	TASK=$(word 1, $(subst /, ,$(call GetCurrentBranch)))       \
	PROG_LANG=$(word 2, $(subst /, ,$(call GetCurrentBranch)))  \
	make -f Makefile run

.PHONY: run
run:
	@if [ -z "$(TASK)" ]; then                  \
        echo "Error: TASK env is not set";      \
        exit 1;                                 \
    fi
	@if [ -z "$(PROG_LANG)" ]; then 		    \
        echo "Error: PROG_LANG env is not set"; \
        exit 1; 						        \
    fi
	$(CONTAINER_WRAP) make -f Makefile clean-wrapped build-wrapped run-wrapped TASK=$(TASK) PROG_LANG=$(PROG_LANG)
