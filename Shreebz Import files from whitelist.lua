
--[[
  
** Notes **
  This script copies a text file list (a "whitelist") of files from a user defined directory.

  Step 1: Execute this script and select your text file.
  Step 2: Select a file in the preferred directory (any file, it doesn't matter white).
  Step 3: Watch it copy everything that's available into the session.

File format notes:
Win file format: "D:\\1-Projects\\01-76\\VOC\\zzzTest\\Reaper Import files from whitelist\\1-Files to copy\\CrScorchedMale\\003BEDF5_1.wav"
OSX file format: /Users/dschreiberjr/Google Drive/1-DTS Audio Main/Reaper/Projects/Import File From Whitelist/Copy From Here/DTS_002_001_02 Stone Slide Drag Grind.wav

]]
-------------
--- Setup ---
-------------

reaper.ClearConsole()

copyPref = reaper.SNM_GetIntConfigVar("copyimpmedia", -666)
--reaper.ShowConsoleMsg("Copy Media on Import is: "..pref.."\n")

if copyPref ~= 1 then
  reaper.ShowConsoleMsg("\"Copy imported media to project media directory\" preference is disabled, it is dangerous to run this script while disabled, so this script will not function until that option is enabled. Please turn it on. ".."\n".."\n".."Goto: Preferences -> Media -> \"Copy imported media to project media directory\". Enable it, it should be the top option. \n\nPlease be sure that your project media directory is defined too. If not, you will likely make a mess of your project folder. \n\n ")
  goto WrongPref
end

userDistance = 5                        -- Distance, in seconds, between end of item and start of next
x = 1                                   -- Variable for iterating table key
whitelist_file_names = {}               -- Creating table of file names
from_path_full = {}                     -- Global table for "from" full path concatenated with file name
Track = reaper.GetLastTouchedTrack()    -- Get last touched track to copy files to
filetype = ".wav"
proj_path = reaper.GetProjectPath("").."/"  -- Get project path
proj_name = reaper.GetProjectName(0, "")    -- Get project name
log_name = " Import log - "..proj_name:gsub(".rpp","")..".txt" -- Log name, minus the .rpp extension

-----------------
--- Functions ---
-----------------

--[[
  a: Extract path -- /Projects/Import File From Whitelist/Copy From Here/
  b: Extract filename -- DTS_002_001_04 Stone Slide Drag Grind.wav
  c: Extract filetype -- wav
]]
function StringExtraction(string)
  a, b, c = string:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
end
--[[
test_string = "/Users/dschreiberjr/Google Drive/1-DTS Audio Main/Reaper/Projects/Import File From Whitelist/Copy From Here/DTS_002_001_04 Stone Slide Drag Grind.wav"
StringExtraction(test_string)
reaper.ShowConsoleMsg("A: "..a.."\n".."B: "..b.."\n".."C: "..c.."\n".."\n")
]]

-- Save cursor position
function SaveCursorPos()
  init_cursor_pos = reaper.GetCursorPosition()
end

-- Restore Cursor position
function RestoreCursorPos()
  reaper.SetEditCurPos(init_cursor_pos, false, false)
end
function MoveCursorPostion(userDistance)
  local curPos = reaper.GetCursorPosition() -- Get cursor position
  userDistance = userDistance + curPos      -- Add user defined time to cursor position
  reaper.SetEditCurPos(userDistance, false, false) -- Move edit cursor forward by userDistance
end

-- Separate file path from filename
function getPath(path)
  return path:gsub('\\','/'):match('.*/')
end

-- Remove return carriage from filenames in whitelist
function removeCharsFromWhitelist(file)
  return file:gsub('\r','')
end

-- Use selected track, or create a new if track is unselected
function trackSelection() 
  if Track == nil then
    Track1 = reaper.Main_OnCommand(40001, 1) -- Insert new track
  else
    reaper.SetTrackSelected(Track, true)
  end
end

function writeLog(s)
log = io.open(proj_path..log_name,"w+")
log:write(s.."\n")
io.close(log)
end

-- Checks if file in whitelist (concatenated with from_path_full) is a valid, readable file.
function validate_files()
  valid_files_table = {}                     -- table of valid files (full path) for import
  valid_log_files = {}                       -- table of valid files for log
  invalid_files_table = {}                   -- table of missing files from import
  whitelist = io.open(filetxt,"r")              -- opening the text file as read only
  aa = 1                                        -- Main loop iterator
  for s in whitelist:lines() do                 -- Start the loop: for each line "s" in the opened text file do something until end
    s = removeCharsFromWhitelist(s)             -- remove return characters from file name
    table.insert(from_path_full,formattedPath..s)   -- Concatenating path with file name from whitelist to table: from_path_full
    --reaper.ShowConsoleMsg("Inserted to from_full_path table: "..from_path_full[aa].."\n")
    if reaper.file_exists(from_path_full[aa]) then          -- If the file is valid, then insert it to its own "valid" table
      table.insert(valid_files_table, formattedPath..s)     -- Valid files path
      table.insert(valid_log_files, s)                      -- Valid files for log
    else                                                    -- If the file is invalid, then insert to its own "invalid" table
      table.insert(invalid_files_table, s)                  -- Missing files for log
    end
    aa = aa + 1                                             -- Increment iterator
  end
  io.close(whitelist)
end

local function printTable(t,title)
  reaper.ShowConsoleMsg(title.."\n")
  for k, v in pairs(t) do
    reaper.ShowConsoleMsg(k .. "\t" .. v .. "\n")
  end
  reaper.ShowConsoleMsg("\n")
end

SaveCursorPos() -- Save initial cursor position

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

userWhitelistBool, filetxt = reaper.GetUserFileNameForRead("", "Whitelist", "txt") -- Opens browser window for whitelist text file.
--reaper.ShowConsoleMsg("Text file used: " .. tostring(filetxt) .. "\n" .. "\n")
--reaper.ShowConsoleMsg(tostring("Init cursor pos: "..init_cursor_pos).."\n".."\n")
if userWhitelistBool then                               -- If the whitelist prompt is Okay'd then continue....
  userPathBool, importedPath = reaper.GetUserFileNameForRead("", "File Path", "wav") -- Opens file browser window. Whitelist text file to read.
  if userPathBool then                                  -- If the folder prompt is Okay'd then continue...
    formattedPath = getPath(importedPath)
    trackSelection()
    validate_files()
    --whitelist = io.open(filetxt,"r")                  -- opening the text file as read only
    for k, v in pairs(valid_files_table) do             -- Loop through the valid files table
      reaper.InsertMedia(v, 0)                          -- Insert media from validate list
      MoveCursorPostion(userDistance)                   -- Move cursor position forward
      --reaper.ShowConsoleMsg("V is: "..v.."\n")
    end
    reaper.TrackList_AdjustWindows(false)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.UpdateTimeline()
    reaper.Main_OnCommand(40290, 1)                     -- Move edit cursor to start of time selection.
    RestoreCursorPos()
    reaper.Undo_EndBlock("Remove list",1)

    
    log = io.open(proj_path..log_name,"w+")             -- Create import log text file in project media directory.
    log:write("Project name: "..proj_name.."\n".."Project path: "..proj_path.."\n")
    log:write("\n".."\n".."\n".."These files were not imported: ")
    for k, v in pairs(invalid_files_table) do
      log:write("\n"..v)                                -- Write log for invalid files
    end
    log:write("\n".."\n".."\n".."\n".."Successfully added these files: ")
    for k, v in pairs(valid_log_files) do
      log:write("\n"..v)                                -- Write log for valid files
    end
    io.close(log)
  else
    -- do nothing
  end

else
  -- do nothing
end

::WrongPref::

