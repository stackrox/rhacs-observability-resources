.PHONY: generate-resources
generate-resources:
	$(MAKE) -C resources/mixins/kubernetes generate
	$(MAKE) -C resources/grafana generate

.PHONY: generate-federate
generate-federate:
	@scripts/generate-federate-match.sh

.PHONY: generate
generate: generate-resources generate-federate

.PHONY: update
update:
	$(MAKE) -C resources/mixins/kubernetes update
