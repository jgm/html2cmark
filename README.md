html2cmark
==========

Lua library to convert HTML5 to commonmark, leveraging
libcmark to write the commonmark and libgumbo to read
the HTML.

To run round-trip tests (HTML -> commonmark -> HTML),
do `make test`.  Note that not all of the tests currently
pass.

