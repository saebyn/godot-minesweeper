extends Control

@onready var scores_container = $CenterContainer/PanelContainer/VBoxContainer/ScoresContainer
@onready var back_button = $CenterContainer/PanelContainer/VBoxContainer/BackButton

# Template for each score entry
const SCORE_ENTRY_TEMPLATE = "%s. %s - %s"

signal return_to_menu

func _ready() -> void:
    populate_scores()

func populate_scores() -> void:
    # Clear any existing score entries
    for child in scores_container.get_children():
        child.queue_free()
        
    # Add a title
    var title = Label.new()
    title.text = "HIGH SCORES"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 32)
    scores_container.add_child(title)
    
    # Add a spacer
    var spacer = Control.new()
    spacer.custom_minimum_size = Vector2(0, 20)
    scores_container.add_child(spacer)
    
    # Get high scores from GameManager
    var high_scores = GameManager.high_scores
    
    if high_scores.size() == 0:
        var no_scores = Label.new()
        no_scores.text = "No scores yet!"
        no_scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        scores_container.add_child(no_scores)
        return
    
    # Add each score entry
    for i in range(high_scores.size()):
        var score = high_scores[i]
        var score_label = Label.new()
        score_label.text = SCORE_ENTRY_TEMPLATE % [str(i + 1), score.initials, str(score.score)]
        score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        score_label.add_theme_font_size_override("font_size", 26)
        scores_container.add_child(score_label)

func _on_back_button_pressed() -> void:
    return_to_menu.emit()
    queue_free()
