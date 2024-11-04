here::i_am('exp1_common_nouns/read_in_data.R')

source(here('_libraries_functions_ggvars.R'))

#### Variable names and sets ####
cn_subjects <- c('04XQ9Z',
                 '0TWPEX',
                 '30A8OF',
                 '3HJU0Y',
                 '55477Y',
                 '9XAKHS',
                 'B0F5F8',
                 'C7P5ZW',
                 'CGKNT4',
                 'D4Q6UZ',
                 'IJVQIC',
                 'J94252',
                 'MJW8U7',
                 'MTTZFQ',
                 'PQZ3M3',
                 'RW8GL8',
                 'W397QP',
                 'WKWBP2',
                 'XAAIY4',
                 'XS93YJ',
                 'YIA080')

trial_type <- c('horsod',
                'rabsou',
                'carsho',
                'dogfir',
                'shewat',
                'babcor',
                'chacow',
                'chitor')

noun_pairs <- c('horse-soda',
                'rabbit-soup',
                'car-shoe',
                'dog-fire',
                'sheep-water',
                'baby-corn',
                'chayote-cow',
                'chicken-tortilla')

nouns <- c('horse',
           'soda',
           'rabbit',
           'soup',
           'car',
           'shoe',
           'dog',
           'fire',
           'sheep',
           'water',
           'baby',
           'corn',
           'chayote',
           'cow',
           'chicken',
           'tortilla')

alts <- c('soda',
          'horse',
          'soup',
          'rabbit',
          'shoe',
          'car',
          'fire',
          'dog',
          'water',
          'sheep',
          'corn',
          'baby',
          'cow',
          'chayote',
          'tortilla',
          'chicken')

pairs <- cbind(target_noun = nouns, non_target_noun = alts)

#### Read in data (output of Ruby script run over Datavyu files) ####
cn_data <- read.csv(here('data/rb_script_exports', 
  'commonNouns_pairedPicture_overlaps3133duration_trial.csv')
  )
cn_data$subject_id <- as.factor(cn_data$subject_id)

## Get demographics
demo <- read.csv(here('data', 
                      'tseltalinfants_participants.csv'))
demo[demo$bebe_meses<10,]$age_group <- '5-9 months'

## Merge coded and demographic data
cn_all <- merge(cn_data, 
                demo[c('subject_id', 'bebe_meses', 'age_group',
                       'mama_edad')], 
                by='subject_id') 

### Add/define new variables ###
cn_all$age_group <- factor(cn_all$age_group, levels=c(
  '5-9 months', '10-13 months', '14-16 months'))

# centered age
cn_all$age_centered <- cn_all$bebe_meses - na.mean(cn_all$bebe_meses)

# specify target/nontarget noun, noun-pair
cn_r2 <- cn_all %>% 
  merge(., pairs, by='target_noun', all=T)

## when no looking, proportion is 0 
cn_r2$post1_nontarget_prop[cn_r2$post1_nontarget_sum_ms==0] <- 0
cn_r2$post1_target_prop[cn_r2$post1_target_sum_ms==0] <- 0

## standardize 'keep' column
cn_r2$keep[cn_r2$keep=='trial was recycled'] <- 'trial_was_recycled'

cn_r2[cn_r2$left_noun %in% c('squash', 'spoon') |
        cn_r2$right_noun %in% c('squash', 'spoon'),]$keep <- 'old_trial_type'

## triallooking_dur_s: duration from first look onset to last look offset
cn_r2$triallooking_dur_s <- 
  (cn_r2$looking_offset_ms - cn_r2$looking_onset_ms)/1000

## total *potential* trial time and proportion infant looking
cn_r2$totaltrialtime_looking_sum_ms <- 
  cn_r2$pre_looking_sum_ms + cn_r2$post1_looking_sum_ms

cn_r2$totaltrialtime_looking_sum_s <- cn_r2$totaltrialtime_looking_sum_ms/1000

cn_r2$totaltrialtime_looking_prop <- cn_r2$totaltrialtime_looking_sum_ms / (
  cn_r2$pre_dur_ms + cn_r2$post1_dur_ms)

# true trial time and proportion infant looking
cn_r2$trialtolookingoffset_dur_s <- 
  (cn_r2$looking_offset_ms - cn_r2$trial_onset_ms)/1000

cn_r2$trialtolookingoffset_prop <- 
  cn_r2$totaltrialtime_looking_sum_ms /
  (cn_r2$looking_offset_ms - cn_r2$trial_onset_ms) 