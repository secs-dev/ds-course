ROOT_PREFIX=../..
MAELSTROM=$(ROOT_PREFIX)/maelstrom/maelstrom
COURSE_NAME=ds-course
IMAGE_NAME=$(COURSE_NAME)
CONTAINER_NAME=$(COURSE_NAME)
CONTAINER_WRAP=docker build -t $(IMAGE_NAME) -f Dockerfile . \
				&& docker run -v .:/$(COURSE_NAME) --rm --name $(CONTAINER_NAME) $(IMAGE_NAME)
TASKS_FOLDER=tasks
TASK_PATH =./$(TASKS_FOLDER)/$(TASK)
ENTER_TASK_DIR=cd $(TASK_PATH) &&
TASK_PROFILES=$(TASK_PATH)/profiles.yml
CURRENT_YEAR=2025
ORGANIZATION=secs-dev-ds-course-$(CURRENT_YEAR)

RUST_BUILD=cargo build
RUST_TARGET_PATH=$(ROOT_PREFIX)/$(TASK_PATH)/target/debug/$(TASK)
RUST_INIT=cargo init . \
			&& cargo add async-trait maelstrom-node \
			&& cargo add serde --features=derive

GO_BUILD=go build
GO_TARGET_PATH=$(ROOT_PREFIX)/$(TASK_PATH)/$(TASK)
GO_INIT=go mod init $(COURSE_NAME)/$(TASK) \
			&& go get github.com/jepsen-io/maelstrom/demo/go \
			&& echo 'package main\nfunc main(){}' > main.go

ifeq ($(PROG_LANG),rust)
TARGET_PATH := $(RUST_TARGET_PATH)
else ifeq ($(PROG_LANG),go)
TARGET_PATH := $(GO_TARGET_PATH)
endif

.PHONY: _build-wrapped
_build-wrapped:
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) $(RUST_BUILD)
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) $(GO_BUILD)
endif

ALLOWED_PROG_LANGS := rust go
.PHONY: _validate-lang
_validate-lang:
	@if [ -z "$(PROG_LANG)" ]; then \
        echo "ERROR: PROG_LANG env cannot be empty"; \
        exit 1; \
    fi
	@if ! echo "$(ALLOWED_PROG_LANGS)" | grep -qw "$(PROG_LANG)"; then \
        echo "ERROR: PROG_LANG env must be one of: [$(ALLOWED_PROG_LANGS)], Got '$(PROG_LANG)'"; \
        exit 1; \
    fi

ALLOWED_TASKS := echo tso broadcast
.PHONY: _validate-task
_validate-task:
	@if [ -z "$(TASK)" ]; then \
        echo "ERROR: TASK env cannot be empty"; \
        exit 1; \
    fi
	@if ! echo "$(ALLOWED_TASKS)" | grep -qw "$(TASK)"; then \
        echo "ERROR: TASK env must be one of: [$(ALLOWED_TASKS)], Got '$(TASK)'"; \
        exit 1; \
    fi

.PHONY: _validate-profile
_validate-profile:
	@if [ -z "$(PROFILE)" ]; then \
    	echo "ERROR: PROFILE env cannot be empty"; \
     	exit 1; \
    fi
	@if [ "$(shell yq .$(PROFILE) $(TASK_PROFILES))" == "null" ]; then \
	   	echo "ERROR: invalid task profile"; \
	   	exit 1; \
	fi

.PHONY: _sim-wrapped
_sim-wrapped:
	$(ENTER_TASK_DIR) $(MAELSTROM) test --bin $(TARGET_PATH) $(shell yq .$(PROFILE) $(TASK_PROFILES))

.PHONY: sim
sim: _validate-task _validate-lang _validate-profile
	$(CONTAINER_WRAP) make -f Makefile _build-wrapped _sim-wrapped TASK=$(TASK) PROG_LANG=$(PROG_LANG) PROFILE=$(PROFILE)

.PHONY: template
template: _validate-task _validate-lang
ifeq ($(PROG_LANG),rust)
	$(ENTER_TASK_DIR) $(RUST_INIT)
else ifeq ($(PROG_LANG),go)
	$(ENTER_TASK_DIR) $(GO_INIT)
endif


.PHONY: clean-jepsen
clean-jepsen:
	@find . -type d -name "store" -exec rm -rf {} +

.PHONY: submit
submit:
	@gh pr create \
		--repo  $(ORGANIZATION)/$(COURSE_NAME) \
    	--base main \
     	--editor

.PHONY: help-maelstrom
help-maelstrom:
	@./maelstrom/maelstrom test --help
