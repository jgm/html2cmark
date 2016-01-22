CMARK_DIR=../cmark
.PHONY: clean, test, all, rock, update, check

all: rock

rock:
	luarocks --local make $(LCMARK_ROCKSPEC)

update: $(TESTS)/spec-tests.lua

$(TESTS)/spec-tests.lua: $(CMARK_DIR)/test/spec.txt
	python3 $(CMARK_DIR)/test/spec_tests.py -d --spec $< | sed -e 's/^\([ \t]*\)"\([^"]*\)":/\1\2 = /' | sed -e 's/^\[/return {/' | sed -e 's/^\]/}/' > $@

check:
	luacheck bin/html2cmark html2cmark.lua

test: check
	lua test.lua

clean:

