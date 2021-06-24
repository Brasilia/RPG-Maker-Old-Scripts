class Game_Map
  attr_accessor :solid_regions
  alias let_initialize initialize
  def initialize
    let_initialize
    @solid_regions = [] if @solid_regions == nil
  end
  alias let_passable? passable?
  def passable?(x, y, d)
    return false if @solid_regions.include?(region_id(x,y))
    let_passable?(x, y, d)
  end
end
