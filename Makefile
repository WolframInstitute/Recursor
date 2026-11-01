WOLFRAMSCRIPT ?= wolframscript

.DEFAULT_GOAL := check
.PHONY: check check-proofs test notebooks check-publish publish all

check:
	$(WOLFRAMSCRIPT) -file scripts/check.wls

check-proofs:
	$(WOLFRAMSCRIPT) -file scripts/check.wls proofs

test:
	$(WOLFRAMSCRIPT) -file scripts/test.wls $(FILES)

notebooks:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls build

check-publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls check

publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls publish

all: check test check-proofs check-publish
