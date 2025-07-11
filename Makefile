MAELSTROM=./maelstrom/maelstrom
IMAGE_NAME=ds-course
CONTAINER_NAME=$(IMAGE_NAME)
CONTAINER_WRAP=docker build -t $(IMAGE_NAME) -f Dockerfile . && \
			   docker run -it --rm --name $(CONTAINER_NAME) $(IMAGE_NAME)
ENTER_TASK_DIR=cd $(TASK) &&

# Maybe move tasks to some general dir
TASKS := task-0 task-1 task-2
GetCurrentBranch = $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: clean-wrapped
clean-wrapped:
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) cargo clean
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) go clean
else
	@echo "Unsupported PROG_LANG env value: ${PROG_LANG}"
	exit 1
endif

.PHONY: build-wrapped
build-wrapped:
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) cargo build --release
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) go build
endif

.PHONY: run-wrapped
run-wrapped:
ifeq ($(PROG_LANG),rust)
	# TODO DEFAULT BIN PATH
else ifeq ($(PROG_LANG),go)
	# TODO DEFAULT BIN PATH
endif
	$(MAELSTROM) test --bin # bin + faults here somehow maybe in env file in each dir

.PHONY: run-ci
run-ci:
	TASK=$(word 2, $(subst /, ,$(call GetCurrentBranch)))       \
	PROG_LANG=$(word 1, $(subst /, ,$(call GetCurrentBranch)))  \
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
