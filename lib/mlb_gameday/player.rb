module MLBGameday
  class Player
    attr_reader :id, :data

    def initialize(id:, xml:)
      @id = id
      @data = xml
      player_attribute_methods unless self.methods.grep(/jersey_number/).any? # don't redefine methods every time
      player_stat_methods unless self.methods.grep(/season_/).any? # don't redefine methods every time
    end

    def name
      "#{first_name} #{last_name}"
    end

    def player_attribute_methods
      player_attributes = @data.xpath('//Player').first.attributes.keys.map(&:to_sym)
      player_attributes.each {|name| Player.define_player_attribute(name)}
    end

    def player_stat_methods
      categories = @data.xpath('//Player/*').map(&:name)
      stats_categories = categories.map { |category| [category, @data.xpath("//Player/#{category}").first.attributes.keys] }
      stats_categories.each { |category, stats| Player.define_player_stat(category, stats) }
    end

    def self.define_player_attribute(name)
      return if self.instance_methods.include? name
      define_method(name) do
        @data.xpath("//Player/@#{name}").text
      end
    end

    def self.define_player_stat(category, stats)
      stats.each do |stat|
        stat_method = "#{category.downcase}_#{stat.downcase}".to_sym
        return if self.instance_methods.include? stat_method
        define_method(stat_method) do
          @data.xpath("//Player/#{category}/@#{stat}").text
        end
      end
    end
  end
end
