require 'ruby2d'

set title: "Xelda"

TILE_SIZE = 40

# Player class
class Player
  attr_reader :x, :y
  attr_accessor :direction

  def initialize(map)
    @map = map
    @x = 9
    @y = 8
    @direction = :up

    #Sprites för spelaren
    @sprites = {
      up: Image.new('sprites/player/tile008.png', width: TILE_SIZE, height: TILE_SIZE),
      down: Image.new('sprites/player/tile004.png', width: TILE_SIZE, height: TILE_SIZE),
      left: Image.new('sprites/player/tile006.png', width: TILE_SIZE, height: TILE_SIZE),
      right: Image.new('sprites/player/tile003.png', width: TILE_SIZE, height: TILE_SIZE)
    }

    update_sprite_position
    update_sprite
  end

  def move(dx, dy)
    new_x = @x + dx
    new_y = @y + dy

    #KOllar att man inte går in i väggar eller utanför mappen
    unless @map.tile_at(new_x, new_y) == 1 || @map.tile_at(new_x, new_y) == 3 || @map.enemy_at(new_x, new_y)
      @x = new_x
      @y = new_y
      update_sprite_position
    end

  
  end

  def face_direction(direction)
    @direction = direction
    update_sprite
  end

  def update_sprite
    #gömmer sprites
    @sprites.each_value(&:remove)

    #Visar bara spriten för rätt riktning
    current_sprite = @sprites[@direction]
    current_sprite.x = @x * TILE_SIZE
    current_sprite.y = @y * TILE_SIZE
    current_sprite.add
  end

  def update_sprite_position
    sprite = @sprites[@direction]
    sprite.x = @x * TILE_SIZE
    sprite.y = @y * TILE_SIZE
  end
end

# Enemy class
class Enemy1
  attr_reader :x, :y

  def initialize(map, player, x, y)
    @map = map
    @player = player
    @x = x
    @y = y
    @sprite = Image.new('sprites/slime.png', width: TILE_SIZE, height: TILE_SIZE)
    @move_delay = 35  #Hur lång tid innan fienden kan röra sig igen
    @timer = 0
  end

  def move_towards_player
    @timer += 1
    return unless @timer >= @move_delay

    @timer = 0

    dx = @player.x - @x
    dy = @player.y - @y

    #Reglerar så att fienderna inte fastnar på grund av väggar eller varandra
    if dx.abs > dy.abs
      move(dx > 0 ? 1 : -1, 0) || move(0, dy > 0 ? 1 : -1)
    else
      move(0, dy > 0 ? 1 : -1) || move(dx > 0 ? 1 : -1, 0)
    end
  end

  def move(dx, dy)
    new_x = @x + dx
    new_y = @y + dy

    
      #Kollar om man går in i en vägg
    unless @map.tile_at(new_x, new_y) == 1 || @map.tile_at(new_x, new_y) == 3 || (@player.x == new_x && @player.y == new_y) || @map.enemy_at(new_x, new_y)
      @x = new_x
      @y = new_y
      @sprite.x = @x * TILE_SIZE
      @sprite.y = @y * TILE_SIZE
    end
  end
end

class Enemy2
  attr_reader :x, :y

  def initialize(map, player, x, y)
    @map = map
    @player = player
    @x = x
    @y = y
    @sprite = Image.new('sprites/ghost.png', width: TILE_SIZE, height: TILE_SIZE)
    @move_delay = 35  #Hur lång tid innan fienden kan röra sig igen 
    @timer = 0
  end

  def move_towards_player
    @timer += 1
    return unless @timer >= @move_delay

    @timer = 0

    dx = @player.x - @x
    dy = @player.y - @y

    #Reglerar så att fienderna inte fastnar på grund av väggar eller varandra
    if dx.abs > dy.abs
      move(dx > 0 ? 1 : -1, 0) || move(0, dy > 0 ? 1 : -1)
    else
      move(0, dy > 0 ? 1 : -1) || move(dx > 0 ? 1 : -1, 0)
    end
  end

  def move(dx, dy)
    new_x = @x + dx
    new_y = @y + dy

    
 
    unless (@player.x == new_x && @player.y == new_y) || @map.enemy_at(new_x, new_y)
      @x = new_x
      @y = new_y
      @sprite.x = @x * TILE_SIZE
      @sprite.y = @y * TILE_SIZE
    end
  end
end



# Map klass
class Map
  attr_reader :width, :height

  def initialize(map_data)
    @width = map_data[0].size
    @height = map_data.size
    @tiles = map_data
    @sprites = []
    render_map
  end

  def render_map
    @tiles.each_with_index do |row, y|
      row.each_with_index do |tile, x|
        case tile
        when 0 #golv    
          @sprites << Sprite.new('sprites\tile199.png', x: x * TILE_SIZE, y: y * TILE_SIZE, height: TILE_SIZE, width: TILE_SIZE)
        when 1 # vägg
          @sprites << Sprite.new('sprites\tile002.png', x: x * TILE_SIZE, y: y * TILE_SIZE, height: TILE_SIZE, width: TILE_SIZE)
        when 3 #hål i marken
          @sprites << Square.new(x: x * TILE_SIZE, y: y * TILE_SIZE, size: TILE_SIZE, color: 'black')
        when 4 # Enemy1 spawnposition
          @sprites << Sprite.new('sprites\tile199.png', x: x * TILE_SIZE, y: y * TILE_SIZE, height: TILE_SIZE, width: TILE_SIZE)
        when 5 # Enemy2 spawnposition
          @sprites << Sprite.new('sprites\tile199.png', x: x * TILE_SIZE, y: y * TILE_SIZE, height: TILE_SIZE, width: TILE_SIZE)
        end
      end
    end
  end

  def tile_at(x, y)
    @tiles[y][x]
  end

  def enemy_at(x, y)
    @enemies.each do |enemy|
      return true if enemy.x == x && enemy.y == y
    end
    false
  end

  #lägger ut rätt fiender på rätt plats
  def spawn_enemies(player)
    @enemies = []
    @height.times do |y|
      @width.times do |x|
        if @tiles[y][x] == 4
          @enemies << Enemy1.new(self, player, x, y)
        elsif @tiles[y][x] == 5
          @enemies << Enemy2.new(self, player, x, y)
        end
      end
    end
  end

  def update_enemies
    @enemies.each(&:move_towards_player)
  end
end


# Map data
map_data1 = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data2 = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 1, 0, 4, 0, 0, 0, 4, 0, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 1, 0, 0, 0, 4, 0, 0, 0, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data3 = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 1, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 4, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 1, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 1, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data4 = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1],
  [1, 3, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1],
  [1, 3, 0, 3, 3, 3, 3, 3, 0, 0, 0, 3, 3, 3, 3, 3, 0, 3, 1],
  [1, 3, 0, 0, 0, 0, 3, 3, 3, 0, 0, 3, 5, 3, 5, 3, 0, 3, 1],
  [1, 3, 3, 3, 3, 0, 3, 3, 3, 0, 0, 3, 0, 3, 0, 3, 0, 3, 1],
  [0, 0, 0, 3, 3, 0, 3, 3, 3, 0, 0, 3, 3, 3, 3, 3, 0, 3, 1],
  [1, 3, 0, 3, 0, 0, 0, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 3, 1],
  [1, 3, 0, 3, 0, 3, 0, 3, 3, 0, 0, 0, 0, 3, 3, 0, 3, 3, 1],
  [1, 3, 0, 3, 0, 3, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 3, 3, 1],
  [1, 3, 5, 0, 0, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 3, 3, 1],
  [1, 3, 3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data5 =[
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 0, 0, 0, 0, 3, 0, 0, 0, 0, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
  [1, 0, 4, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 4, 0, 1],
  [1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 4, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 4, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data6 =[
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 3, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0],
  [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data7 =[
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data8 =[
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

map_data9 =[
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]


set width: map_data1[0].size * TILE_SIZE, height: map_data1.size * TILE_SIZE

map = Map.new(map_data1)

player = Player.new(map)
map.spawn_enemies(player)

#spelkontroller för spleren
on :key_down do |event|
  case event.key
  when 'w'
    if player.direction != :up
      player.face_direction(:up)
    else
      player.move(0, -1)
    end
  when 's'
    if player.direction != :down
      player.face_direction(:down)
    else
      player.move(0, 1)
    end
  when 'a'
    if player.direction != :left
      player.face_direction(:left)
    else
      player.move(-1, 0)
    end
  when 'd'
    if player.direction != :right
      player.face_direction(:right)
    else
      player.move(1, 0)
    end
  end
end

current_map = 1  #Variabel för nuvarande rum man är i

update do
  map.update_enemies

  player_position = ("#{player.x}" + "#{player.y}").to_i

  #Om spelaren är på en viss possition i ett visst rum laddas en ny mapp (dörr)
  if player_position == 90 || player_position == 912 || player_position == 06 || player_position == 186
    if current_map == 1
      current_map = 2
      map = Map.new(map_data2)
    elsif current_map == 2 
      if player_position == 06
        current_map = 3
        map = Map.new(map_data3)
      elsif player_position == 912
        current_map = 1
        map = Map.new(map_data1)
      elsif player_position == 90
        current_map = 4
        map = Map.new(map_data4)
      elsif player_position == 186
        current_map = 7
        map = Map.new(map_data7)
      end
    elsif current_map == 3
      if player_position == 186
        current_map = 2
        map = Map.new(map_data2)
      elsif player_position == 912
        current_map = 5
        map = Map.new(map_data5)
      end
    elsif current_map == 4
      if player_position == 912
        current_map = 2
        map = Map.new(map_data2)
      elsif player_position == 06
        current_map = 6
        map = Map.new(map_data6)
      end
    elsif current_map == 5
      if player_position == 90
        current_map = 3
        map = Map.new(map_data3)
      end
    elsif current_map == 6
      if player_position == 186
        current_map = 4
        map = Map.new(map_data4)
      end
    elsif current_map == 7
      if player_position == 06
        current_map = 2
        map = Map.new(map_data2)
      elsif player_position == 90
        current_map = 9
        map = Map.new(map_data9)
      elsif player_position == 912
        current_map = 8
        map = Map.new(map_data8)
      end
    elsif current_map == 8
      if player_position == 90
        current_map = 7
        map = Map.new(map_data7)
      end
    elsif current_map == 9
      if player_position == 912
        current_map = 7
        map = Map.new(map_data7)
      end
    end

    #Ser till att fiender och spelaren visas i nästa rum
    player = Player.new(map)
    map.spawn_enemies(player)
  end
end



show
