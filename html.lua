local to_ssg = require("luax.utils.to_ssg")
local html = to_ssg({ entry_path = "dist/_app", out_path = "index.html" })
print(html)
