MAELSTROM=./maelstrom/maelstrom
LOOKUP_MAP=./lookup.yml



IMAGE_NAME=ds-course
CONTAINER_NAME=ds-course
CONTAINER_WRAP=docker build -t $(IMAGE_NAME) -f Dockerfile . && \
			   docker run -it --rm --name $(CONTAINER_NAME) $(IMAGE_NAME)

get_model_binary = $(shell yq -r ".$(TASK)" $(LOOKUP_MAP))

.PHONY: clean
clean:


.PHONY: run-model
run-model:
	@if [ -z "$(TASK)" ]; then \
        echo "Error: TASK is not set"; \
        exit 1; \
    fi
	@echo "Trying run model [$(TASK)] ..."
	$(CONTAINER_WRAP) $(MAELSTROM) test --bin $(call get_model_binary)
