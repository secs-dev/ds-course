ROOT_PREFIX=../..
MAELSTROM=$(ROOT_PREFIX)/maelstrom/maelstrom
COURSE_NAME=ds-course
IMAGE_NAME=$(COURSE_NAME)
CONTAINER_NAME=$(COURSE_NAME)
CONTAINER_WRAP=docker build -t $(IMAGE_NAME) -f Dockerfile . && \
			   docker run -v .:/$(COURSE_NAME) --rm --name $(CONTAINER_NAME) $(IMAGE_NAME)
TASKS_FOLDER=tasks
TASK_PATH =./$(TASKS_FOLDER)/$(TASK)
ENTER_TASK_DIR=cd $(TASK_PATH) &&
TASK_PROFILES=$(TASK_PATH)/profiles.yml

RUST_BUILD=cargo build
RUST_CLEAN=cargo clean
RUST_TARGET_PATH=$(ROOT_PREFIX)/$(TASK_PATH)/target/debug/$(TASK)

GO_BUILD=go build
GO_CLEAN=go clean
GO_TARGET_PATH=$(ROOT_PREFIX)/$(TASK_PATH)/$(TASK)


.PHONY: clean-jepsen
clean-jepsen:
	find . -type d -name "store" -exec rm -rf {} +


ALLOWED_TASKS := echo tso
ALLOWED_PROG_LANGS := rust go
.PHONY: validate
validate:
	@if [ -z "$(TASK)" ]; then                  \
        echo "ERROR: TASK env cannot be empty"; \
        exit 1;                                 \
    fi
	@if ! echo "$(ALLOWED_TASKS)" | grep -qw "$(TASK)"; then                      \
        echo "ERROR: TASK env must be one of: [$(ALLOWED_TASKS)], Got '$(TASK)'"; \
        exit 1;                                                                   \
    fi
	@if [ -z "$(PROG_LANG)" ]; then                     \
        echo "ERROR: PROG_LANG env cannot be empty";    \
        exit 1;                                         \
    fi
	@if ! echo "$(ALLOWED_PROG_LANGS)" | grep -qw "$(PROG_LANG)"; then                           \
        echo "ERROR: PROG_LANG env must be one of: [$(ALLOWED_PROG_LANGS)], Got '$(PROG_LANG)'"; \
        exit 1;                                                                                  \
    fi
	@if [ -z "$(PROFILE)" ]; then                     \
       echo "ERROR: PROFILE env cannot be empty";    \
       exit 1;                                         \
    fi
	@if [ "$(shell yq .$(PROFILE) $(TASK_PROFILES))" == "null" ]; then                     \
      echo "ERROR: invalid task profile";    \
      exit 1;                                         \
   fi

ifeq ($(PROG_LANG),rust)
TARGET_PATH := $(RUST_TARGET_PATH)
else ifeq ($(PROG_LANG),go)
TARGET_PATH := $(GO_TARGET_PATH)
endif


.PHONY: clean-wrapped
clean-wrapped:
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) $(RUST_CLEAN)
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) $(GO_CLEAN)
endif

.PHONY: build-wrapped
build-wrapped:
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) $(RUST_BUILD)
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) $(GO_BUILD)
endif

.PHONY: run-wrapped
run-wrapped:
	$(ENTER_TASK_DIR) $(MAELSTROM) test --bin $(TARGET_PATH) $(shell yq .$(PROFILE) $(TASK_PROFILES))

.PHONY: run
run: validate
	$(CONTAINER_WRAP) make -f Makefile clean-wrapped build-wrapped run-wrapped TASK=$(TASK) PROG_LANG=$(PROG_LANG) PROFILE=$(PROFILE)
