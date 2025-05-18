extends Node

var scores_path: String = "user://high_scores.cfg"

signal game_over(player_won: bool)
signal game_started()

class Score extends Resource:
  var score: int
  var initials: String

  func _init(score_: int, initials_: String) -> void:
    self.score = score_
    self.initials = initials_

@export var high_scores: Array[Score] = []


func reset_game() -> void:
  game_started.emit()