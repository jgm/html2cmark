CMARK_DIR=../cmark

test: spec-tests.lua
	prove test.t

spec-tests.lua: $(CMARK_DIR)/test/spec.txt
	python3 $(CMARK_DIR)/test/spec_tests.py -d --spec $(CMARK_DIR)/test/spec.txt | sed -e 's/^\([ \t]*\)"\([^"]*\)":/\1\2 = /' | sed -e 's/^\[/return {/' | sed -e 's/^\]/}/' > $@


