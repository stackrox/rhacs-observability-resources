.PHONY: generate
generate:
	$(MAKE) -C resources/mixins/kubernetes generate
	$(MAKE) -C resources/grafana generate
