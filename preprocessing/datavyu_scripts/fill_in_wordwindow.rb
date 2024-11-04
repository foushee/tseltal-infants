require 'Datavyu_API'

#DIR = ENV['HOME'] + '/wkspaces/TseltalInfants/3_coded_videos/greeting_pairedPicture'
#DIR = ENV['HOME'] + '/wkspaces/TseltalInfants/3_coded_videos/commonNouns_pairedPicture'

#files = get_datavyu_files_from(DIR, true)
#files.each do |file|

begin
    #path = File.join(DIR, file)
    #log_puts "\nLoading #{file}"

    #if path =~ /_old\//i || path =~ /\/old_.*\//i
      #log_puts "Skipping because it has \"old\" in the name"
      #num_skipped+= 1
     # next
    #end

#    $db, $pj = loadDB(path)

   wordWindow = add_codes_to_column("wordWindow", "period")
   setColumn("wordWindow", wordWindow)
   end
   
   window_column = getColumn('wordWindow')

   case window_column.cells.length
   #when 1
   #   window_column.cells[0].period = "target"
   #when 2
   #   window_column.cells[0].period = "pre"
   #   window_column.cells[1].period = "target"
   when 3
      window_column.cells[0].period = "pre"
      window_column.cells[1].period = "speech"
      window_column.cells[2].period = "target"
      set_column("wordWindow", window_column)
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

