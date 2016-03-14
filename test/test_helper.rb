# Mock the basic `open` function so we don't actually hit the MLB website
class MockedApi < MLBGameday::API
  alias_method :old_open, :open

  def open(url, &block)
    dir = File.dirname __FILE__
    base = url.gsub 'http://gd2.mlb.com/components/game/mlb/', ''
    path = File.join dir, base

    unless File.exist?(path)
      puts "Downloading from website: #{url}"

      return old_open(url, &block)
    end

    file = File.open path

    return file unless block_given?

    block.call file
  end
end

DYNAMIC_GAME_METHODS = %i(
  ampm aw_lg_ampm away_ampm away_code away_division away_file_code
  away_games_back away_games_back_wildcard away_league_id away_loss
  away_name_abbrev away_preview_link away_recap_link away_sport_code
  away_team_city away_team_errors away_team_hits away_team_id away_team_name
  away_team_runs away_time away_time_zone away_win balls day double_header_sw
  first_pitch_et game_data_directory game_nbr game_pk game_type gameday_link
  gameday_sw hm_lg_ampm home_ampm home_code home_division home_file_code
  home_games_back home_league_id home_loss home_name_abbrev home_preview_link
  home_recap_link home_sport_code home_team_city home_team_errors home_team_hits
  home_team_id home_team_name home_team_runs home_time home_time_zone home_win id
  ind inning inning_state league note original_date outs photos_link preview
  scheduled_innings status strikes tbd_flag tiebreaker_sw time time_aw_lg
  time_date time_date_aw_lg time_date_hm_lg time_hm_lg time_zone time_zone_aw_lg
  time_zone_hm_lg top_inning tv_station tz_aw_lg_gen tz_hm_lg_gen venue venue_id
  venue_w_chan_loc wrapup_link
)
