package = "html2cmark"
version = "0.24.0-1"
source = {
    url = "git://github.com/jgm/html2cmark",
    tag = "0.24.0"
}
description = {
    summary = [[Convert HTML to Markdown]],
    detailed = [[html2cmark provides a library and command line program
      for converting HTML to Markdown. The output is CommonMark but should
      be compatible with most flavors of Markdown.  libgumbo is used for
      parsing HTML, and libcmark for rendering CommonMark.]],
    homepage = "https://github.com/jgm/html2cmark",
    license = "BSD2",
    maintainer = "John MacFarlane <jgm@berkeley.edu>",
}
dependencies = {
   "lua >= 5.2",
   "cmark >= 0.24",
   "gumbo >= 0.4",
   "optparse >= 1.0.1",
}
build = {
    type = "builtin",
    modules = {
        html2cmark = "html2cmark.lua"
    },
    install = {
        bin = { html2cmark = "bin/html2cmark" }
    }
}
