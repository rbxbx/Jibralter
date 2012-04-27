JASMINE_NODE = node_modules/jasmine-node/bin/jasmine-node

test:
	$(JASMINE_NODE) --coffee --verbose specs
