MAELSTROM=./maelstrom/maelstrom
IMAGE_NAME=ds-course
CONTAINER_NAME=$(IMAGE_NAME)
CONTAINER_WRAP=docker build -t $(IMAGE_NAME) -f Dockerfile . && \
			   docker run -it --rm --name $(CONTAINER_NAME) $(IMAGE_NAME)

# Maybe move tasks to some general dir
TASKS := task-0


GetCurrentBranch = $(shell git rev-parse --abbrev-ref HEAD)
GetStudentExecutable = $(shell make --no-print-directory -C $(TASK) -f Makefile get-path)
CleanStudentDir = $(shell make -C $(1) -f Makefile clean)
BUILD_STUDENT_EXECUTABLE=make -C $(TASK) -f Makefile build




.PHONY: clean
clean:
	$(foreach task,$(TASKS),$(call CleanStudentDir,$(task)))
	rm -rf ./store

.PHONY: run-ci
run-ci:
	make -f Makefile run TASK=$(call GetCurrentBranch)

.PHONY: run
run:
	@if [ -z "$(TASK)" ]; then \
        echo "Error: TASK is not set"; \
        exit 1; \
    fi
	$(CONTAINER_WRAP) make -f Makefile run-wrapped TASK=$(TASK)

.PHONY: run-wrapped
run-wrapped:
	$(BUILD_STUDENT_EXECUTABLE)
	$(MAELSTROM) test --bin $(call GetStudentExecutable) # + faults here somehow
