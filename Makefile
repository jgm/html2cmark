VERSION=0.24.0
REVISION=1
ROCKSPEC=html2cmark-$(VERSION)-$(REVISION).rockspec
CMARK_DIR=../cmark

.PHONY: clean, test, all, rock, update, check

all: rock

rock: $(ROCKSPEC)
	luarocks --local make $(ROCKSPEC)

update: $(TESTS)/spec-tests.lua

$(TESTS)/spec-tests.lua: $(CMARK_DIR)/test/spec.txt
	python3 $(CMARK_DIR)/test/spec_tests.py -d --spec $< | sed -e 's/^\([ \t]*\)"\([^"]*\)":/\1\2 = /' | sed -e 's/^\[/return {/' | sed -e 's/^\]/}/' > $@

$(ROCKSPEC): rockspec.in
	sed -e "s/_VERSION/$(VERSION)/g; s/_REVISION/$(REVISION)/g" $< > $@

check:
	luacheck bin/html2cmark html2cmark.lua

test: check
	lua test.lua

clean:
	-rm -r $(ROCKSPEC)
