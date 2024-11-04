require 'Datavyu_API'

# GOAL: 
# fill in wordWindow column values: for common nouns, "pre", "speech", "target"; for greetings: "pre", "target"
# reinterpret leftlooks and rightlooks timestamps **relative to onset of "target" window** for that trial (00:00:00:00ms)
# export data BY FRAME, from trial onset (some variably large negative number) to 3500ms after the onset of "target" window
# make new column with where child looking at each frame: "target_image", "nontarget_image", "neither"

require 'Datavyu_API'

$log = File.open(__FILE__ + '.log', 'w')
def log_puts(s)
  $stderr.puts s
  $log.puts s
end

#DIR = ENV['HOME'] + '/wkspaces/TseltalInfants/3_coded_videos/greeting_pairedPicture'
DIR = ENV['HOME'] + '/wkspaces/TseltalInfants/3_coded_videos/commonNouns_pairedPicture'

files = get_datavyu_files_from(DIR, true)
files.each do |file|
  path = File.join(DIR, file)
  log_puts "\nLoading #{file}"

  $db, $pj = loadDB(path)

  window_column = getColumn('wordWindow')
  log_puts window_column.inspect
#end

   #window_column = add_codes_to_column("wordWindow", "period")
   #setColumn("wordWindow", wordWindow)
end
   
   window_column = getColumn('wordWindow')

   case window_column.cells.length
   #when 1
   #   window_column.cells[0].period = "target"
   #when 2
   #   window_column.cells[0].period = "pre"
   #   window_column.cells[1].period = "target"
   when 3
      window_column.cells[0].argvals = "pre"
      window_column.cells[1].argvals = "speech"
      window_column.cells[2].argvals = "target"
      set_column("wordWindow", window_column)
      log_puts window_column.cells[0].argvals
   end

   #case window_cells.length
   #when 1
   #   window_cells[0].period = ""
   #when 2
   #   window_cells[0].period = "speech"
   #   window_cells[1].period = "target"
   #when 3
  #    window_cells[0]
  #set_column(window_column)
   #end
#    case window_cells.length
#    when 1
#      target_cell = window_cells[0]
#    when 2
#      pre_sp_cell, target_cell = window_cells
#    when 3
#      pre_sp_cell, sp_cell, target_cell = window_cells
#    else
#      fail "Invalid number of wordWindow cells: #{window_cells.length} should be 2 or 3"
#      #fail "Invalid number of wordWindow cells: #{window_cells.length} should be 1, 2, or 3"
#    end

