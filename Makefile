WOLFRAMSCRIPT ?= wolframscript

.DEFAULT_GOAL := check
.PHONY: check check-proofs test notebooks hero check-publish publish style style-fix all

check:
	$(WOLFRAMSCRIPT) -file scripts/check.wls
	$(WOLFRAMSCRIPT) -file scripts/style.wls check

# Check the code against docs/coding-guides, or FILES="..."; style-fix applies the mechanical fixes.
style:
	$(WOLFRAMSCRIPT) -file scripts/style.wls check $(FILES)

style-fix:
	$(WOLFRAMSCRIPT) -file scripts/style.wls fix $(FILES)

check-proofs:
	$(WOLFRAMSCRIPT) -file scripts/check.wls proofs

test:
	$(WOLFRAMSCRIPT) -file scripts/test.wls $(FILES)

notebooks:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls build

# Redraw docs/Hero.png, the resource page image, from docs/Hero.wl. HERO names its design.
HERO ?= 1
hero:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls hero $(HERO)

check-publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls check

publish:
	$(WOLFRAMSCRIPT) -file scripts/docs.wls publish

all: check test check-proofs check-publish
