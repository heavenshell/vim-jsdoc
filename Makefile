.PHONY: install
install:
	bash lib/install.sh

.PHONY: clean
clean:
	rm -rf lib/lehre lib/node_modules lib/yarn.lock
