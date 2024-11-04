require 'Datavyu_API'

DIR = ENV['HOME'] + '/wkspaces/TseltalInfants/3_coded_videos/greeting_pairedPicture'
#DIR = ENV['HOME'] + '/wkspaces/TseltalInfants/3_coded_videos/commonNouns_pairedPicture'

# ONLY_FILES is an array of opf paths that are relative to DIR. When set, we analyze only those files, instead of
# everything under DIR.
ONLY_FILES = nil
#ONLY_FILES = ['greeting_pairedPicture/TI-04XQ9Z_gpp/TI-04XQ9Z_gpp_SS/young_woman-OLD_MAN_SS_2.opf']
#ONLY_FILES = ['greeting_pairedPicture/TI-0TWPEX_gpp/TI-0TWPEX_gpp_SS/old_man-YOUNG_WOMAN_SS.opf']

KNOWN_CODERS = %w{SS XZ NG RF CK} 

#removed firework from STIMULI:
STIMULI = %w{dog baby crybaby chicken old_man old_woman young_man young_woman}
LEFT = 0
RIGHT = 1
# Order swapped for subject's perspective
LEFT_LOOK = 1
RIGHT_LOOK = 0

# Datavyu cells cover inclusive ranges of frames. A cell starts at the beginning of the onset frame, and ends at the end
# of the offset frame.
INCLUSIVE_RANGE = true

# Continue to the next file when we fail
KEEP_GOING = true

# If set to a number, don't keep processing files after we've reached that many errors.
ERROR_LIMIT = nil

# Serial number for logfile
VERSION = 3

# Some optional warnings:
WARN_BLANK_ID_CODES = false
WARN_MISSING_WORD_WINDOW_CODES = false

# Put a bunch of extra debug output behind this flag:
$verbose = false

$log = File.open(__FILE__ + '.log', 'w')
def log_puts(s)
  $stderr.puts s
  $log.puts s
end

log_puts RUBY_VERSION if $verbose

log_puts "Version #{VERSION}"

def cell_range(cell)
  debug_label = "#{cell.inspect}"

  fail "Point cells have no duration: #{debug_label}" if cell.onset > 0 && cell.offset == 0

  range = [cell.onset, cell.offset]

  unless (!INCLUSIVE_RANGE && range_duration(range, debug_label) == cell.duration) ||
         (INCLUSIVE_RANGE && range_duration(range, debug_label) == cell.duration + 1)
    fail "Range duration (#{range_duration(range)}) does not match cell duration (#{cell.duration})"
  end

  range
end

def range_duration(range, debug_label = '')
  fail "Invalid range: #{debug_label} #{range.inspect}" if range.last < range.first

  if INCLUSIVE_RANGE
    (range.last - range.first) + 1
  else
    fail "Empty range: #{debug_label} #{range.inspect}" if range.last == range.first

    range.last - range.first
  end
end

def range_duration_field(name, range)
  [name, range_duration(range, name)]
end

def range_overlap(range1, range2)
  log_puts "Testing #{range1} vs #{range2}" if $verbose
  start = [range1[0], range2[0]].max
  finish = [range1[1], range2[1]].min
  if finish > start
    [start, finish]
  else
    nil
  end
end

def format_ms(ms)
  min = ms / 60000
  sec = (ms % 60000) / 1000.0
  "%02u:%06.3f" % [min, sec]
end

csv_path = File.join(DIR, "#{DIR.split('/').last}-overlaps3133duration-alltrials.csv")
log_puts "Writing to #{csv_path}"

def find_overlaps(cells, window_range)
  overlaps = []
  cells.each do |cell|
    range = cell_range(cell)
    overlap = range_overlap(range, window_range)
    next unless overlap
    log_puts "Overlap range: #{overlap.inspect}" if $verbose
    overlaps << overlap
  end
  overlaps
end

def check_non_overlap(ranges)
  log_puts "Checking #{ranges.inspect} for non-overlap" if $verbose
  ranges = ranges.sort_by(&:first)
  ranges.each_cons(2) do |(range1, range2)|
    fail "Ranges that should not overlap do: #{range1} vs #{range2}" if range1[1] >= range2[0]
  end
end

def ranges_duration(ranges)
  (ranges.map { |range| range_duration(range) }).reduce(0, :+)
end

def get_code(cell, code, allow_missing = false)
  column = get_column(cell.parent)
  unless column.arglist.include?(code)
    err_msg = "#{cell.parent} does not have code #{code}: valid codes are #{column.arglist}"
    if allow_missing
      warn(err_msg)
      return
    else
      fail err_msg
    end
  end
  cell.get_code(code)
end

def check_window_cell(cell, name, warn_duration, max_duration)
  column = get_column(cell.parent)
  if !column.arglist.include?('code01')
    if WARN_MISSING_WORD_WINDOW_CODES
      warn "wordWindow cell missing code: cell at #{format_ms(cell.onset)} should have code01=#{name}"
    end
  else
    cell_name = cell.get_code('code01')
    if cell_name != name
      fail "wordWindow code does not match: cell at #{format_ms(cell.onset)} code01=#{cell_name}, should be #{name}"
    end
  end

  cell_range(cell) # Validate the cell's onset/offset

  if cell.duration > warn_duration * 1000
    if cell.duration > max_duration * 1000
      warn "wordWindow has unlikely duration: #{name} cell at #{format_ms(cell.onset)} has duration #{format_ms(cell.duration)} > #{max_duration}s"
    end

    warn "wordWindow has unlikely duration: #{name} cell at #{format_ms(cell.onset)} has duration #{format_ms(cell.duration)} > #{warn_duration}s"
  end
end

def check_window_contig(cell1, cell2)
  unless cell1.offset + 1 == cell2.onset
    fail "wordWindow cells are not contiguous: cell##{cell1.ordinal} at #{format_ms(cell1.onset)} has offset #{format_ms(cell1.offset)}" +
      " which does not match cell##{cell2.ordinal} onset #{format_ms(cell2.onset)}"
  end
end

def look_up_noun(abbr)
  STIMULI.each { | stimuli | return stimuli if abbr==stimuli[0,3] }
  fail "No noun found for abbreviation: #{abbr}. Valid abbreviations are: #{STIMULI.map { |s| s[0, 3] } }"
end

$person_re = /^(young|old)_(woman|man)$/

# was:
#def parse_stimuli_names(name)
#  names = name.split('-')
#  if names.length == 2
#    prompt_flags = names.map { |name| name == name.upcase }
#  elsif names.length == 3 && names[2] == 'NG'
#    names = names[0..1]
#    prompt_flags = names.map { |name| name.match($person_re) != nil } # match? in Ruby 2
#    fail "one name must match #{$person_re.inspect}" unless prompt_flags.any?
#  else
#    fail "#{name} should have format <left_stimulus>-<right_stimulus> with optional -NG suffix"
#  end
# have not edited yet but need to support new naming convention
#01-horsod-horse-L-XZ
def parse_stimuli_names(name)
  names = name.split('-')
  if names.length == 2
    prompt_flags = names.map { |name| name == name.upcase }
  elsif names.length == 3 && names[2] == 'NG'
    names = names[0..1]
    prompt_flags = names.map { |name| name.match($person_re) != nil } # match? in Ruby 2
    fail "one name must match #{$person_re.inspect}" unless prompt_flags.any?
  else
    fail "#{name} should have format <left_stimulus>-<right_stimulus> with optional -NG suffix"
  end

  fail 'one name must be the prompt' unless prompt_flags.any?
  fail 'both names cannot be the prompt' if prompt_flags.all?
  target_index = prompt_flags.find_index(true)

  names.each do |name|
    fail "Unknown stimulus #{name}. Add it to STIMULI if necessary" unless STIMULI.include?(name.downcase)
  end

  log_puts "#{names.inspect} target_index #{target_index}" if $verbose
  [names, target_index]
rescue RuntimeError
  fail "Invalid stimuli names: #{name}: #{$!}"
end

def fetch_single_cell(column_or_col_name)
  column = column_or_col_name.kind_of?(String) ? getVariable(column_or_col_name) : column_or_col_name
  cells = column.cells
  fail "Missing #{column.name} cell" unless cells.length > 0
  fail "Multiple #{column.name} cells in column" if cells.length > 1
  cells.first
end

def fetch_single_code(col_name)
  cell = fetch_single_cell(col_name)
  code = cell.get_code('code01')
  fail "Missing #{col_name} code" unless code
  code
end

def check_prefix(s, prefix, optional = false)
  unless s.start_with?(prefix)
    fail "Prefix missing: #{s} does not have #{prefix} prefix" unless optional
    s
  else
    s[(prefix.length)..-1]
  end
end

def check_suffix(s, suffix, optional = false)
  unless s.end_with?(suffix)
    fail "Missing suffix: #{s} does not have #{suffix} suffix" unless optional
    s
  else
    s[0..(-1 - suffix.length)]
  end
end

def split_name(name, sep, min_components, max_components, template)
  parts = name.split(sep)
  fail "#{name} should have form #{template}" unless parts.length >= min_components && parts.length <= max_components
  parts
end

def check_id_field(id_cell, code, value, synonyms = {})
  cell_value = get_code(id_cell, code)
  if cell_value == ''
    warn("id.#{code} code is blank") if WARN_BLANK_ID_CODES
    return
  end
  unless cell_value == value
    if cell_value.downcase == value
      warn("id.#{code} code has wrong case #{cell_value.inspect} vs #{value.inspect}")
      return
    end

    if (value_syns = synonyms[value]) && value_syns.include?(cell_value)
      warn("id.#{code} code contains #{cell_value.inspect}, which is a synonym for #{value.inspect}, but isn't exactly right")
      return
    end

    fail "id.#{code} does not match filename: #{cell_value.inspect} vs #{value.inspect}"
  end
end

num_succeeded = 0
num_skipped = 0
num_failed = 0
$failure_reasons = Hash.new { |hsh, key| hsh[key] = 0 }
$num_warnings = 0

def warn(msg)
  log_puts "WARNING: " + msg
  $num_warnings+= 1
end

if ONLY_FILES
  files = ONLY_FILES
else
  files = get_datavyu_files_from(DIR, true)
end
files.each do |file|
  notes = nil

  begin
    path = File.join(DIR, file)
    log_puts "\nLoading #{file}"

    if path =~ /_old\//i || path =~ /\/old_.*\//i
      log_puts "Skipping because it has \"old\" in the name"
      num_skipped+= 1
      next
    end

    $db, $pj = loadDB(path)

    coder_column = getVariable('coder')
    coder_cells = coder_column.cells
    coder_cell = coder_cells.first
    warn "Missing first coder cell" unless coder_cell
    notes = coder_cell.get_code('notes')
    warn("Additional coder cells not supported yet") if coder_cells.length > 1

    # Path example: greeting_pairedPicture/TI-XAAIY4_gpp/TI-XAAIY4_gpp_SS/OLD_WOMAN-young_man_SS.opf
    path_components = path.split('/').last(4)
    fail "Path should have at least 4 components: #{path}" unless path_components.length == 4
    #if path_components.length == 3
    #  long_task_name, subject_task, trial_name_coder = path_components
    #elsif path_components.length == 4
      long_task_name, subject_task, subject_task_coder, trial_name_coder = path_components
    #else
    #  fail "Path #{file} should have three components with formats: <long-task>/TI-<subject-id>_<task>/<trial-name>_<coder>.opf"
    #end

    if subject_task =~ / \(\w+@berkeley.edu\)$/
      log_puts "Skipping because it's a Box Sync duplicate"
      num_skipped+= 1
      next
    end

    short_task, trial_type_code = case long_task_name
                                  when 'greeting_pairedPicture' then ['gpp', 'greeting_paired']
                                  when 'greeting_fancy' then ['fg', 'greeting_fancy']
                                  when 'commonNouns_pairedPicture' then ['cn', 'common_nouns']
                                  when 'test_test' then ['t', 'test']
                                  else fail "Unknown long-task name: #{long_task_name}"
                                  end

    block_name, trial_type = long_task_name.split('_')

    subject_task = check_prefix(subject_task, 'TI-', true)
    subject_task = check_suffix(subject_task, "_#{short_task}", true)
    subject_id = subject_task

    trial_name_coder = check_suffix(trial_name_coder, '.opf')
    log_puts "trial_name_coder: #{trial_name_coder}" if $verbose

    coders = []
    variant = nil
    loop do
      if trial_name_coder =~ /_(\d+)$/
        fail "Multiple variant numbers" if variant
        variant = $1.to_i
        trial_name_coder = $`
      elsif trial_name_coder =~ /-NG$/
        break
      elsif trial_name_coder =~ /[-_]([A-Z][A-Z])$/
        coders.unshift($1)
        trial_name_coder = $`
      else
        break
      end
    end

    trial_name = trial_name_coder

=begin
    check_stimulus(left_stimulus)
    check_stimulus(right_stimulus)

    if left_stimulus == right_stimulus
      log_puts "Skipping because #{left_stimulus} == #{right_stimulus}"
      num_skipped+= 1
      next
    end

    fail "#{left_stimulus} and #{right_stimulus} differ only in case" if left_stimulus.downcase == right_stimulus.downcase

    if left_stimulus == 'blank' || right_stimulus == 'blank'
      log_puts "Skipping because #{left_stimulus} or #{right_stimulus} are \"blank\""
      num_skipped+= 1
      next
    end
=end

    coders.each do |coder|
      fail "Unknown coder #{coder}. Add them to KNOWN_CODERS in #{$0}" unless KNOWN_CODERS.include?(coder)
    end

    warn("No coders in filename") unless coders.length > 0

    if path_components.length == 4
      subject_task_coder = check_prefix(subject_task_coder, 'TI-', true)
      subject_task_coder = check_prefix(subject_task_coder, "#{subject_id}_")
      subject_task_coder = check_prefix(subject_task_coder, "#{short_task}_", true)

      coders2 = split_name(subject_task_coder, '_', 1, 2, "<coder1>_<coder2>...")
      warn("Coders in different parts of path don't match: #{coders} vs. #{coders2}") unless coders2 == coders
    end

    # Not all trials are numbered yet; mostly common_nouns should be, but others may be as well
    trial_number = if trial_name =~ /^(\d\d)-/
                     trial_name = $'
                     $1.to_i
                   end

    if trial_name =~ /^(blank|FIREWORK)-(blank|FIREWORK)(_\d)?$/
      warn "Skipping fireworks trial that should not have been coded"
      num_skipped+= 1
      next
    end

    if trial_name =~ /^(baby|dog|chicken)-(baby|dog|chicken)(_\d)?$/
      warn "Skipping trial type not currently being analyzed"
      num_skipped+= 1
      next
    end

    if short_task == 'cn' && trial_number
      noun_pair, target_noun, target_side_init = trial_name.split('-')
      next if noun_pair == ''
      nouns = noun_pair[0,3], noun_pair[3,3]
      nouns = nouns.map{ | noun | look_up_noun(noun)}
      target_noun_index = nouns.find_index(target_noun)
      fail "Target noun not found in noun pair: #{target_noun}" unless target_noun_index
      target_index = case target_side_init
      when 'L' 
        LEFT
      when 'R'
        RIGHT
      else 
        fail "Invalid target_side_init (not L/R)"
      end 
      stimuli_names = [nil, nil] 
      stimuli_names[target_index] = target_noun
      stimuli_names[1-target_index] = nouns[1-target_noun_index]
    else
      stimuli_names, target_index = parse_stimuli_names(trial_name)
    end

    id_cell = fetch_single_cell('id')
    check_id_field(id_cell, 'ssid', subject_id, {"TI-#{subject_id}" => subject_id})
    check_id_field(id_cell, 'trialtype', trial_type_code, {'greeting_paired' => ['greeting']})
    check_id_field(id_cell, 'l', stimuli_names[LEFT].downcase)
    check_id_field(id_cell, 'r', stimuli_names[RIGHT].downcase)
    check_id_field(id_cell, 'target', stimuli_names[target_index].downcase)

    keep = get_code(id_cell, 'keep_01', true)
    log_puts "keep: #{keep}" if $verbose

    window_column = getVariable('wordWindow')
    fail 'Missing wordWindow column' unless window_column
    window_cells = window_column.cells

    pre_sp_cell = sp_cell = nil
    case window_cells.length
    #when 1
    #  target_cell = window_cells[0]
    when 2
      pre_sp_cell, target_cell = window_cells
    #when 3
    #  pre_sp_cell, sp_cell, target_cell = window_cells
    else
      fail "Invalid number of wordWindow cells: #{window_cells.length} should be 2 or 3"
      #fail "Invalid number of wordWindow cells: #{window_cells.length} should be 1, 2, or 3"
    end
    check_window_cell(pre_sp_cell, 'pre', 5, 8)
    check_window_contig(pre_sp_cell, sp_cell) if sp_cell
    check_window_cell(sp_cell, 'sp', 6, 6) if sp_cell
    check_window_contig(sp_cell, target_cell) if sp_cell && target_cell
    check_window_cell(target_cell, 'target', 16, 2000)

    trial_onset = window_cells.first.onset
    trial_offset = window_cells.last.offset

    leftlooks = getVariable('leftlooks').cells
    rightlooks = getVariable('rightlooks').cells
    looking_onset_ms = [leftlooks.first, rightlooks.first].compact.map(&:onset).min
    looking_offset_ms = [leftlooks.last, rightlooks.last].compact.map(&:offset).max # NEW OFFSET

    # Note that pre_sp != pre (more specifically preT/pre_target)
    pre_onset = trial_onset
    post1_onset = target_cell.onset + 367
    pre_offset = post1_onset - 1
    post2_onset = target_cell.onset + 3500
    #post2_onset = post1_onset + 3500
    post1_offset = post2_onset - 1
    #unless trial_offset <= post2_onset
      #fail "Target wordWindow too short: post2_onset is #{post2_onset}, trial_offset is #{trial_offset}"
    #  warn "Target wordWindow too short: post2_onset is #{post2_onset}, trial_offset is #{trial_offset}"
    #end
    #post2_offset = trial_offset
    #trial_looking_onset = trial_onset
    trial_looking_offset = looking_offset_ms

    fields = [['subject_id', subject_id],
              ['test_block', block_name],
              ['keep', keep],
              ['trial_type', trial_type],
              # TODO: sequence
              # TODO: new_trial_name
              ['old_trial_name', trial_name],
              ['noun_pair', stimuli_names.map(&:downcase).sort.join('-')],
              ['left_noun', stimuli_names[LEFT].downcase], ['right_noun', stimuli_names[RIGHT].downcase],
              ['target_noun', stimuli_names[target_index].downcase], ['target_side', %w{left right}[target_index]],
              ['time_unit', 'ms'],
              ['trial_dur_s', range_duration([trial_onset, trial_offset], 'trial_dur_s') / 1000.0],
              #['trial_looking_dur_s', range_duration([trial_looking_onset, trial_looking_offset], 'trial_looking_dur_s') / 1000.0], # NEW CALC
              ['trial_onset_ms', trial_onset],
              ['looking_onset_ms', looking_onset_ms],
              ['looking_offset_ms', looking_offset_ms],
              ['sp_onset_ms', sp_cell && sp_cell.onset],
              ['pre_onset_ms', pre_onset], ['pre_offset_ms', pre_offset],
              range_duration_field('pre_dur_ms', [pre_onset, pre_offset]),
              range_duration_field('post_dur_ms', [post1_onset, trial_offset]),# added 03/29/21 RF
              ['post1_onset_ms', post1_onset], ['post1_offset_ms', post1_offset],
              #['looking_dur_ms', range_duration([looking_onset_ms, trial_looking_offset], 'looking_dur_ms')],
              range_duration_field('post1_dur_ms', [post1_onset, post1_offset]),
              #range_duration_field('trial_looking_dur_ms', [trial_looking_onset, trial_looking_offset])
              #['post2_onset_ms', post2_onset], ['post2_offset_ms', post2_offset],
              #range_duration_field('post2_dur_ms', [post2_onset, post2_offset])
            ]

    labeled_ranges = []
    labeled_ranges << ['pre', [pre_onset, pre_offset]]
    labeled_ranges << ['post', [post1_onset, trial_offset]]
    labeled_ranges << ['post1', [post1_onset, post1_offset]] #analysis window
    #labeled_ranges << ['post2', [post2_onset, post2_offset]]

    labeled_ranges.each do |(label, window_range)|
      overlaps = [nil, nil]
      longest_looks = [nil, nil]
      sums = [nil, nil]
      looking_sum = nil
      proportions = [nil, nil]

      if window_range
        overlaps[LEFT_LOOK] = find_overlaps(leftlooks, window_range)
        overlaps[RIGHT_LOOK] = find_overlaps(rightlooks, window_range)
        longest_looks[LEFT] = (overlaps[LEFT].map { |range| range_duration(range) }).max
        longest_looks[RIGHT] = (overlaps[RIGHT].map { |range| range_duration(range) }).max
        sums[LEFT] = ranges_duration(overlaps[LEFT])
        sums[RIGHT] = ranges_duration(overlaps[RIGHT])
        all_looks = overlaps.flatten(1)
        check_non_overlap(all_looks)
        looking_sum = ranges_duration(all_looks)
        if looking_sum != 0
          proportions[LEFT] = sums[LEFT] / looking_sum.to_f
          proportions[RIGHT] = sums[RIGHT] / looking_sum.to_f
        end
      end

      fields << ["path", path]
      fields << ["#{label}_looking_sum_ms", looking_sum]
      fields << ["#{label}_left_sum_ms", sums[LEFT]]
      fields << ["#{label}_right_sum_ms", sums[RIGHT]]
      fields << ["#{label}_target_sum_ms", sums[target_index]]
      fields << ["#{label}_nontarget_sum_ms", sums[1 - target_index]]
      fields << ["#{label}_target_prop", proportions[target_index]]
      fields << ["#{label}_nontarget_prop", proportions[1 - target_index]]
      fields << ["#{label}_target_longest_look_ms", longest_looks[target_index]]
      fields << ["#{label}_nontarget_longest_look_ms", longest_looks[1 - target_index]]
    end

    fields+= [['coder', coder_cell.get_code('name')],
              ['date_coded', coder_cell.get_code('date')],
              ['coder_comments', notes]]

    unless $csv
      $csv = CSV.open(csv_path, 'w', headers: fields.map(&:first), write_headers: true)
    end

    if $verbose
      fields.each do |(field, value)|
        log_puts "#{field}: #{value}"
      end
    end

    $csv << fields.to_h

    num_succeeded+= 1

  rescue RuntimeError
    log_puts "ERROR: #{file} failed: #{$!}"
    log_puts "NOTES: #{notes}" if notes && notes.length > 0
    num_failed+= 1
    $failure_reasons[$!.message.split(':').first]+= 1
    exit 1 unless KEEP_GOING
    if ERROR_LIMIT && num_failed >= ERROR_LIMIT
      log_puts "Error limit reached, giving up"
      exit 1
    end
  ensure
    $db = $pj = nil
  end
end

log_puts "\n#{num_succeeded} Succeeded, #{num_skipped} Skipped, #{$num_warnings} Warnings, #{num_failed} Failed"
fail "*** Totals don't match" unless num_succeeded + num_skipped + num_failed == files.length

log_puts ''
($failure_reasons.to_a.sort_by { |value| -value[1] }).each do |(reason, count)|
  log_puts "#{reason}: #{count}"
end

$csv.close if $csv

$log.close

