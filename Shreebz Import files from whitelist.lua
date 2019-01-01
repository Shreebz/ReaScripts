
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

userDistance = 5                        -- Distance, in seconds, between end of item and start of next
x = 1                                   -- Variable for iterating table key
file_names_table = {}                   -- Creating table of file names
final_path_table = {}                   -- Global table for full path concatenated with file name
Track = reaper.GetLastTouchedTrack()    -- Get last touched track to copy files to
log_name = " Import log.txt"
filetype = ".wav"
proj_path = reaper.GetProjectPath("").."/"
reaper.ShowConsoleMsg("Project path: ".."\n"..proj_path.."\n".."\n")

-----------------
--- Functions ---
-----------------

function StringExtraction(string)
  a, b, c = string:match("(.-)([^\\/]-%.?([^%.\\/]*))$")
end

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

SaveCursorPos() -- Save initial cursor position

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- Opens file browser window. Text file to read.
userWhitelistBool, filetxt = reaper.GetUserFileNameForRead("", "Whitelist", "txt") 
reaper.ShowConsoleMsg("Text file used: " .. tostring(filetxt) .. "\n" .. "\n")

--reaper.ShowConsoleMsg(tostring("Init cursor pos: "..init_cursor_pos).."\n".."\n")

if userWhitelistBool then
  userPathBool, importedPath = reaper.GetUserFileNameForRead("", "File Path", "wav") -- Opens file browser window. Whitelist text file to read.
  if userPathBool then
    formattedPath = getPath(importedPath)
    trackSelection()
    whitelist = io.open(filetxt,"r")        -- opening the text file as read only
    log = io.open(proj_path..log_name,"w+")
      for s in whitelist:lines() do         -- Start the loop: for each line "s" in the opened text file do something until end
      s = removeCharsFromWhitelist(s)       -- remove return characters from file name
      table.insert(file_names_table,s)      -- Make table for file name
      table.insert(final_path_table,formattedPath..s..filetype) -- Concatenating path with file name from whitelist to new table
      reaper.InsertMedia(final_path_table[x],0)       -- Insert filename
      reaper.ShowConsoleMsg("File Name: "..file_names_table[x].."\n")
      reaper.ShowConsoleMsg("Full Path: "..final_path_table[x].."\n".."\n")
      MoveCursorPostion(userDistance)       -- Moves edit cursor position forward by 5
      --log:write(s.."\n")                    -- Write log
      x = x + 1                             -- Increment array index
    end
    reaper.TrackList_AdjustWindows(false)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.UpdateTimeline()
    io.close(whitelist)
    io.close(log)
    reaper.Main_OnCommand(40290, 1)         -- Move edit cursor to start of time selection.
    RestoreCursorPos()
    reaper.Undo_EndBlock("Remove list",1)
  else
    -- do nothing
  end

else
  -- do nothing
end