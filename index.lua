local to_ssg = require("lib.luax.utils.to_ssg")
local html = to_ssg({ entry_path = "build/_bundle", out_path = "index.html" })
print(html)
