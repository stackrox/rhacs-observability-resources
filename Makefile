.PHONY: generate
generate:
	$(MAKE) -C resources/mixins/kubernetes generate

.PHONY: update
update:
	$(MAKE) -C resources/mixins/kubernetes update
