extends Node2D

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var reveal_sound: AudioStream
@export var flag_sound: AudioStream
@export var explode_sound: AudioStream
@export var win_sound: AudioStream

# Size of the game map in tiles
@export var map_size := Vector2i(9, 9)

@export var unrevealed_tile := Vector2i(0, 0)
@export var mine_tile := Vector2i(1, 0)
@export var revealed_tiles: Array[Vector2i] = [
  Vector2i(2, 0), # Tile for revealed state (0 adjacent mines)
  Vector2i(0, 1), # 1 mine adjacent
  Vector2i(1, 1), # 2 mines adjacent
  Vector2i(2, 1), # 3 mines adjacent
  Vector2i(3, 1), # 4 mines adjacent
  Vector2i(0, 2), # 5 mines adjacent
  Vector2i(1, 2), # 6 mines adjacent
  Vector2i(2, 2), # 7 mines adjacent
  Vector2i(3, 2) # 8 mines adjacent
]
@export var flag_tile := Vector2i(3, 0)
@export var exploding_mine_tile := Vector2i(0, 3)

@export var mine_percent := 0.2

var mine_count: int = 0
var flag_count: int = 0
var player_hit_mine: bool
var player_hit_mine_location: Vector2i

@onready var map: TileMapLayer = $TileMapLayer
@onready var mines_remaining_label: Label = $HUD/MineCount
@onready var map_size_menu: MenuButton = $HUD/MenuButton


class AdjacentTileIterator:
  # An iterator to iterate over adjacent tiles
  var tile_pos: Vector2i
  var map_size: Vector2i
  var tiles: Array[Vector2i] = []
  var current_index: int = 0

  func _init(tile_pos_: Vector2i, map_size_: Vector2i) -> void:
    self.tile_pos = tile_pos_
    self.map_size = map_size_

    for dx in [-1, 0, 1]:
      for dy in [-1, 0, 1]:
        if dx == 0 and dy == 0:
          continue
        var adj_pos = tile_pos + Vector2i(dx, dy)
        if adj_pos.x >= 0 and adj_pos.x < map_size.x and adj_pos.y >= 0 and adj_pos.y < map_size.y:
          tiles.append(adj_pos)

  func _iter_init(_arg) -> bool:
    current_index = 0
    return tiles.size() > 0

  func _iter_next(_arg) -> bool:
    current_index += 1
    return current_index < tiles.size()

  func _iter_get(_arg) -> Vector2i:
    return tiles[current_index]


# enum of reveal states
enum RevealState {
  UNREVEALED,
  REVEALED,
  FLAGGED
}

var started := false # Set to true when the player reveals the first tile
var MINES: Array
var REVEALED_TILES: Array


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  map_size_menu.get_popup().id_pressed.connect(on_map_size_menu_id_pressed)
  GameManager.game_started.connect(reset_game)


func reset_game() -> void:
  mine_count = int(map_size.x * map_size.y * mine_percent)
  player_hit_mine = false
  flag_count = 0
  started = false
  update_hud()
  center_tilemap()
  MINES = create_multidimensional_array(map_size, false)
  REVEALED_TILES = create_multidimensional_array(map_size, RevealState.UNREVEALED)
  update_tilemap()

func on_map_size_menu_id_pressed(id: int) -> void:
  # Change the map size based on the selected menu item
  match id:
    0: map_size = Vector2i(9, 9)
    1: map_size = Vector2i(16, 16)
    2: map_size = Vector2i(30, 16)
    _:
      return

  # Reset the game state
  started = false
  mine_count = int(map_size.x * map_size.y * mine_percent)
  update_hud()
  
  # Reinitialize the mines and revealed tiles
  MINES = create_multidimensional_array(map_size, false)
  REVEALED_TILES = create_multidimensional_array(map_size, RevealState.UNREVEALED)
  
  # Update the tilemap
  update_tilemap()
  
  # Center the tilemap again
  center_tilemap()


func center_tilemap():
  # Get the tile size
  var cell_size := map.tile_set.tile_size
  
  # Calculate the total grid size in pixels
  var grid_size := map_size * cell_size
  
  # Get the viewport size
  var viewport_size := get_viewport_rect().size
  
  # Calculate the position to center the tilemap
  var pos = (viewport_size - Vector2(grid_size)) / 2
  
  # Set the position of the tilemap
  map.position = pos

func create_multidimensional_array(size: Vector2i, initial: Variant) -> Array:
  # Create a multidimensional array of the specified size
  var arr := []
  for i in range(size.x):
    arr.append([])
    for j in range(size.y):
      arr[i].append(initial)
  return arr

func place_mines(first_tile: Vector2i) -> void:
  # Randomly place mines on the map
  for _m in range(mine_count):
    var x: int
    var y: int
    while true:
      x = randi() % map_size.x
      y = randi() % map_size.y
      # Check if the position already has a mine, if so, find a new position
      if MINES[x][y]:
        continue

      # Ensure the first tile does not contain a mine
      if Vector2i(x, y) == first_tile:
        continue

      break
    
    MINES[x][y] = true


func update_hud() -> void:
  # Update the HUD with the number of mines remaining
  mines_remaining_label.text = str(mine_count - flag_count)


func update_tilemap() -> void:
  # Update the TileMap with the mine positions
  map.clear()
  for x in range(map_size.x):
    for y in range(map_size.y):
      match [MINES[x][y], REVEALED_TILES[x][y]]:
        [true, RevealState.UNREVEALED]:
          map.set_cell(Vector2i(x, y), 0, unrevealed_tile)
        [true, RevealState.REVEALED]:
          map.set_cell(Vector2i(x, y), 0, mine_tile)
        [true, RevealState.FLAGGED]:
          map.set_cell(Vector2i(x, y), 0, flag_tile)
        [false, RevealState.UNREVEALED]:
          map.set_cell(Vector2i(x, y), 0, unrevealed_tile)
        [false, RevealState.REVEALED]:
          map.set_cell(Vector2i(x, y), 0, revealed_tiles[count_adjacent_mines(Vector2i(x, y))])
        [false, RevealState.FLAGGED]:
          map.set_cell(Vector2i(x, y), 0, flag_tile)

  if player_hit_mine:
    # If the player hit a mine, reveal the mine location
    map.set_cell(player_hit_mine_location, 0, exploding_mine_tile)


func reveal_tile(tile_pos: Vector2i) -> bool:
  # Reveal the tile at the specified position
  if REVEALED_TILES[tile_pos.x][tile_pos.y] != RevealState.UNREVEALED:
    return false

  # If the tile is a mine, reveal it and end the game
  if MINES[tile_pos.x][tile_pos.y]:
    player_hit_mine = true
    player_hit_mine_location = tile_pos
    return false

  # Mark the tile as revealed
  REVEALED_TILES[tile_pos.x][tile_pos.y] = RevealState.REVEALED
  update_tilemap()

  # Check for adjacent mines and reveal surrounding tiles if necessary
  var adjacent_mines := count_adjacent_mines(tile_pos)
  if adjacent_mines == 0:
    reveal_adjacent_tiles(tile_pos)

  # We have successfully revealed a tile
  return true

func toggle_tile_flag(tile_pos: Vector2i) -> void:
  # Toggle the flag state of the tile at the specified position
  if REVEALED_TILES[tile_pos.x][tile_pos.y] == RevealState.UNREVEALED:
    REVEALED_TILES[tile_pos.x][tile_pos.y] = RevealState.FLAGGED
    flag_count += 1
  elif REVEALED_TILES[tile_pos.x][tile_pos.y] == RevealState.FLAGGED:
    REVEALED_TILES[tile_pos.x][tile_pos.y] = RevealState.UNREVEALED
    flag_count -= 1

  update_hud()


# Reveal all unflagged adjacent tiles when right-clicking on a revealed tile
# This should only be allowed if the number of flags matches the number of adjacent mines
func reveal_unflagged_adjacent_tiles(tile_pos: Vector2i) -> void:
  assert(REVEALED_TILES[tile_pos.x][tile_pos.y] == RevealState.REVEALED)

  var adjacent_mines := count_adjacent_mines(tile_pos)
  var adjacent_flags := count_adjacent_flags(tile_pos)

  # Only reveal adjacent tiles if the number of flags matches the number of adjacent mines
  if adjacent_mines == adjacent_flags:
    reveal_adjacent_tiles(tile_pos)


func game_over() -> void:
  if player_hit_mine:
    audio_player.stream = explode_sound
  else:
    audio_player.stream = win_sound
  
  audio_player.play()
  reveal_all_tiles()
  update_tilemap()
  GameManager.game_over.emit(not player_hit_mine)

func reveal_all_tiles() -> void:
  # Reveal all tiles on the map
  for x in range(map_size.x):
    for y in range(map_size.y):
      REVEALED_TILES[x][y] = RevealState.REVEALED


func count_adjacent_mines(tile_pos: Vector2i) -> int:
  # Count the number of mines adjacent to the specified tile
  var count := 0
  var iterator := AdjacentTileIterator.new(tile_pos, map_size)
  for adj_pos in iterator:
      if MINES[adj_pos.x][adj_pos.y]:
        count += 1
  return count

func count_adjacent_flags(tile_pos: Vector2i) -> int:
  # Count the number of flags adjacent to the specified tile
  var count := 0
  var iterator := AdjacentTileIterator.new(tile_pos, map_size)
  for adj_pos in iterator:
    if REVEALED_TILES[adj_pos.x][adj_pos.y] == RevealState.FLAGGED:
      count += 1

  return count

func reveal_adjacent_tiles(tile_pos: Vector2i) -> void:
  # Recursively reveal adjacent tiles if they are not mines
  var iterator := AdjacentTileIterator.new(tile_pos, map_size)
  for adj_pos in iterator:
    if REVEALED_TILES[adj_pos.x][adj_pos.y] == RevealState.UNREVEALED:
      reveal_tile(adj_pos)

func _unhandled_input(event: InputEvent) -> void:
  # Handle input events
  if event is InputEventMouseButton and event.pressed:
    var mouse_pos = map.get_local_mouse_position()
    var tile_pos = map.local_to_map(mouse_pos)

    # Check if the clicked tile is within the map bounds
    if tile_pos.x < 0 or tile_pos.x >= map_size.x or tile_pos.y < 0 or tile_pos.y >= map_size.y:
      return

    # do different actions based on the mouse button pressed
    if event.button_index == MOUSE_BUTTON_LEFT:
      # Left click to reveal the tile
      handle_left_click(tile_pos)
    elif event.button_index == MOUSE_BUTTON_RIGHT:
      # Right click to flag the tile
      handle_right_click(tile_pos)

    # Check if the game is over
    if player_hit_mine:
      game_over()
    elif check_win_condition():
      game_over()


func check_win_condition() -> bool:
  # Check if all non-mine tiles are revealed
  for x in range(map_size.x):
    for y in range(map_size.y):
      if not MINES[x][y] and REVEALED_TILES[x][y] != RevealState.REVEALED:
        return false
  return true

func handle_left_click(tile_pos: Vector2i) -> void:
  # If the game has not started, place mines and reveal the first tile
  if not started:
    place_mines(tile_pos)
    started = true

  # Reveal the clicked tile
  if reveal_tile(tile_pos):
    audio_player.stream = reveal_sound
    audio_player.play()

func handle_right_click(tile_pos: Vector2i) -> void:
  # Don't do anything if the game has not started
  if not started:
    return
  
  if REVEALED_TILES[tile_pos.x][tile_pos.y] == RevealState.REVEALED:
    reveal_unflagged_adjacent_tiles(tile_pos)
  else:
    toggle_tile_flag(tile_pos)

  audio_player.stream = flag_sound
  audio_player.play()
  
  update_tilemap()
