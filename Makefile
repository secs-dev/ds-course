MAELSTROM=./maelstrom/maelstrom
LOOKUP_MAP=./lookup.yml

get_model_binary = $(shell yq -r ".$(TASK)" $(LOOKUP_MAP))

.PHONY: clean
clean:


.PHONY: docker-wrap
docker-wrap:

.PHONY: run-model
run-model: docker-wrap
	@if [ -z "$(TASK)" ]; then \
        echo "Error: TASK is not set"; \
        exit 1; \
    fi
	@echo "Trying run model [$(TASK)] ..."
	$(MAELSTROM) --bin $(call get_model_binary)
