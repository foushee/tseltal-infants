here::i_am('exp2_greetings/read_in_data.R')

source(here('_libraries_functions_ggvars.R'))

#### Variable names and sets ####
g_subjects <- c('04XQ9Z',
                '0KA7RC',
                '0TWPEX',
                '2H3DMT',
                '30A8OF',
                '3HJU0Y',
                '44ZXT0',
                'B0F5F8',
                '9XAKHS',
                'C7P5ZW',
                'CGKNT4',
                'IJVQIC',
                'J94252',
                'MJW8U7',
                'MTTZFQ',
                'N07Z54',
                'RW8GL8',
                'WKWBP2',
                'XAAIY4',
                'XS93YJ',
                'YIA080')

g_old_trial_names <- c('old_woman-YOUNG_MAN', 'OLD_WOMAN-young_man', 
                      'young_man-OLD_WOMAN', 'YOUNG_MAN-old_woman',
                      'old_man-YOUNG_WOMAN', 'OLD_MAN-young_woman',
                      'YOUNG_WOMAN-old_man', 'young_woman-OLD_MAN')

#### Read in data (output of Ruby script run over Datavyu files) ####
g_data <- read.csv(here('data/rb_script_exports',
                  'greeting_pairedPicture_overlaps3133duration_alltrials.csv')
                  ) %>%
  filter(old_trial_name %in% g_old_trial_names)

g_data$subject_id[g_data$subject_id=='BOF5F8'] <- 'B0F5F8'
g_data$subject_id <- as.factor(g_data$subject_id)

g_data$post1_nontarget_prop[g_data$post1_nontarget_sum_ms==0] <- 0
g_data$post1_target_prop[g_data$post1_target_sum_ms==0] <- 0

g_data$keep[g_data$post_looking_sum_ms==0] <- 'no_post_naming_looking'

## Get demographics
demo <- read.csv(here('data', 'tseltalinfants_participants.csv'))
demo[demo$bebe_meses<10,]$age_group <- '5-9 months'

## Merge coded and demographic data
g_all <- merge(g_data, demo[c('subject_id', 'bebe_meses', 
                              'sexo', 'age_group')], 
               by=c('subject_id')) 

#### Add/define new variables ####
g_all$age_group <- factor(g_all$age_group, levels=c(
  '5-9 months', '10-13 months', '14-16 months'))

# centered age
g_all$age_centered <- g_all$bebe_meses - na.mean(g_all$bebe_meses)

# looking time duration from first onset to last offset
g_all$triallooking_dur_s <- 
  (g_all$looking_offset_ms - g_all$looking_onset_ms)/1000

## total potential trial time and proportion infant looking
g_all$totaltrialtime_looking_sum_ms <- 
  g_all$pre_looking_sum_ms + g_all$post_looking_sum_ms

g_all$totaltrialtime_looking_sum_s <- g_all$totaltrialtime_looking_sum_ms/1000

g_all$totaltrialtime_looking_prop <- g_all$totaltrialtime_looking_sum_ms / (
  g_all$pre_dur_ms + g_all$post_dur_ms
  )

# true trial time and proportion infant looking
g_all$trialtolookingoffset_dur_s <- 
  (g_all$looking_offset_ms - g_all$trial_onset_ms)/1000

g_all$trialtolookingoffset_prop <- 
  g_all$totaltrialtime_looking_sum_ms /
  (g_all$looking_offset_ms - g_all$trial_onset_ms) 

g_r2 <- g_all 
g_r2$exclusions <- g_r2$keep
g_r2$exclusions[g_r2$exclusions=='keep'] <- ''


cols <- c("subject_id", "bebe_meses", "sexo", "age_group", "age_centered", "coder", "date_coded", "test_block", "trial_type", "old_trial_name", "noun_pair", "left_noun", "right_noun", "target_noun", "target_side", "time_unit", "trial_dur_s", "trial_onset_ms", "looking_onset_ms", "looking_offset_ms", "sp_onset_ms", "pre_onset_ms", "pre_offset_ms", "pre_dur_ms", "post_dur_ms", "post1_onset_ms", "post1_offset_ms", "post1_dur_ms", "path", "pre_looking_sum_ms", "pre_left_sum_ms", "pre_right_sum_ms", "pre_target_sum_ms", "pre_nontarget_sum_ms", "pre_target_prop", "pre_nontarget_prop", "pre_target_longest_look_ms", "pre_nontarget_longest_look_ms", "post_looking_sum_ms", "post_left_sum_ms", "post_right_sum_ms", "post_target_sum_ms", "post_nontarget_sum_ms", "post_target_prop", "post_nontarget_prop", "post_target_longest_look_ms",     "post_nontarget_longest_look_ms", "post1_looking_sum_ms", "post1_left_sum_ms", "post1_right_sum_ms", "post1_target_sum_ms", "post1_nontarget_sum_ms", "post1_target_prop", "post1_nontarget_prop", "post1_target_longest_look_ms", "post1_nontarget_longest_look_ms", "triallooking_dur_s", "totaltrialtime_looking_sum_ms", "totaltrialtime_looking_prop", "trialtolookingoffset_dur_s", "trialtolookingoffset_prop", "totaltrialtime_looking_sum_s")