local base = "https://raw.githubusercontent.com/yourname/cc-project/main/"

local function download(url, path)
  local res = http.get(url)
  if not res then
    print("Failed:", url)
    return false
  end

  -- Create folder if needed
  local dir = fs.getDir(path)
  if dir ~= "" and not fs.exists(dir) then
    fs.makeDir(dir)
  end

  local file = fs.open(path, "w")
  file.write(res.readAll())
  file.close()
  res.close()

  print("Downloaded:", path)
  return true
end

-- Get manifest
local res = http.get(base .. "manifest.json")
if not res then error("Failed to fetch manifest") end

local manifest = textutils.unserializeJSON(res.readAll())
res.close()

-- Download all files
for _, file in ipairs(manifest.files) do
  download(base .. file, file)
end

print("✅ Full repo installed!")