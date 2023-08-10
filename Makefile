.PHONY: generate
generate:
	$(MAKE) -C resources/mixins/kubernetes generate
	$(MAKE) -C resources/grafana generate

.PHONY: update
update:
	$(MAKE) -C resources/mixins/kubernetes update
