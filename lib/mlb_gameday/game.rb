module MLBGameday
  # This class is just too long. It might be able to be split up, but it's not
  # likely to happen any time soon. For now, we'll disable the cop.
  # rubocop:disable Metrics/ClassLength
  class Game
    attr_reader :gid, :home_team, :away_team, :linescore, :gamecenter, :boxscore

    def initialize(api, gid, linescore: nil, gamecenter: nil, boxscore: nil)
      @api = api
      @gid = gid

      @linescore  = linescore
      @gamecenter = gamecenter
      @boxscore   = boxscore

      define_game_attribute_methods unless self.methods.grep(/first_pitch_et/).any? # don't redefine every time

      @home_team = @api.team home_name_abbrev
      @away_team = @api.team away_name_abbrev
    end

    def teams
      [@home_team, @away_team]
    end

    def home_start_time(ampm: true)
      if ampm
        "#{home_time} #{home_ampm} #{home_time_zone}"
      else
        "#{home_time} #{home_time_zone}"
      end
    end

    def away_start_time(ampm: true)
      if ampm
        "#{away_time} #{away_ampm} #{away_time_zone}"
      else
        "#{away_time} #{away_time_zone}"
      end
    end

    # [3, Top/Middle/Bottom/End]
    def inning
      return [0, '?'] unless inning

      [inning.to_i,
       inning_state]
    end

    def runners
      first, second, third = [nil, nil, nil]

      [first, second, third]
    end

    def tied?
      return true if away_team_runs == home_team_runs
      false
    end

    def over?
      ['Final', 'Game Over', 'Completed Early'].include? status
    end
    alias_method :fat_lady_has_sung?, :over?

    def in_progress?
      status == 'In Progress'
    end

    def started?
      over? || in_progress?
    end

    def postponed?
      status == 'Postponed'
    end

    def home_record
      [home_win,
       home_loss].map(&:to_i)
    end

    def away_record
      [away_win,
       away_loss].map(&:to_i)
    end

    def current_pitcher
      return nil unless in_progress?

      @api.pitcher @linescore.xpath('//game/current_pitcher/@id').text,
                   year: date.year
    end

    def opposing_pitcher
      return nil unless in_progress?

      @api.pitcher @linescore.xpath('//game/opposing_pitcher/@id').text,
                   year: date.year
    end

    def winning_pitcher
      return nil unless over?

      @api.pitcher @linescore.xpath('//game/winning_pitcher/@id').text,
                   year: date.year
    end

    def losing_pitcher
      return nil unless over?

      @api.pitcher @linescore.xpath('//game/losing_pitcher/@id').text,
                   year: date.year
    end

    def save_pitcher
      return nil unless over?

      @api.pitcher @linescore.xpath('//game/save_pitcher/@id').text,
                   year: date.year
    end

    def away_starting_pitcher
      @linescore.xpath('//game/away_probable_pitcher/@id').text
    end

    def home_starting_pitcher
      @linescore.xpath('//game/home_probable_pitcher/@id').text
    end

    def score
      return [0, 0] unless in_progress? || over?

      [home_team_runs,
       away_team_runs].map(&:to_i)
    end

    def home_pitcher
      # Spring training games can end in ties, in which case there's
      # really no pitching data. This should really return a null object.
      case status
      when 'In Progress'
        # The xpath changes based on which half of the inning it is
        if top_inning == 'Y'
          opposing_pitcher
        else
          current_pitcher
        end
      when 'Preview', 'Warmup', 'Pre-Game'
        @api.pitcher home_starting_pitcher
      when 'Final'
        home, away = score

        home > away ? winning_pitcher : losing_pitcher
      end
    end

    def away_pitcher
      # Spring training games can end in ties, in which case there's
      # really no pitching data. This should really return a null object.
      case status
      when 'In Progress'
        # The xpath changes based on which half of the inning it is
        if top_inning == 'Y'
          current_pitcher
        else
          opposing_pitcher
        end
      when 'Preview', 'Warmup', 'Pre-Game'
        @api.pitcher away_starting_pitcher
      when 'Final', 'Game Over'
        home, away = score

        home > away ? losing_pitcher : winning_pitcher
      end
    end

    def current_linescore
      innings = @linescore.xpath('//game/linescore')
      innings.each_with_object({}) do |inning, linescore|
        inning_number = inning.attributes["inning"].value
        home_team_runs = inning.attributes["home_inning_runs"].value
        away_team_runs = inning.attributes["away_inning_runs"].value
        linescore[inning_number] = [home_team_runs, away_team_runs]
      end

    end

    def home_tv
      return nil unless @gamecenter

      @gamecenter.xpath('//game/broadcast/home/tv').text
    end

    def away_tv
      return nil unless @gamecenter

      @gamecenter.xpath('//game/broadcast/away/tv').text
    end

    def home_radio
      return nil unless @gamecenter

      @gamecenter.xpath('//game/broadcast/home/radio').text
    end

    def away_radio
      return nil unless @gamecenter

      @gamecenter.xpath('//game/broadcast/away/radio').text
    end

    def free?
      @linescore.xpath('//game/game_media/media/@free').text == 'ALL'
    end

    def date
      @date ||= Chronic.parse original_date
    end

    # So we don't get huge printouts
    def inspect
      %(#<MLBGameday::Game @gid="#{@gid}">)
    end

    def define_game_attribute_methods
      game_attributes = @linescore.xpath('//game').first.attributes.keys.map(&:to_sym)
      game_attributes.each {|name| Game.define_attribute(name)}
    end

    # Defines all hte game attributes as methods
    def self.define_attribute(name)
      define_method(name) do
        @linescore.xpath("//game/@#{name}").text
      end
    end

  end
end
