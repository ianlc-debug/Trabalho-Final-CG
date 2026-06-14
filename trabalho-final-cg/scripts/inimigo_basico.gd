extends Node3D 

@export var velocidade: float = 5.0

func _process(delta):
	var seguidor = get_parent()
	
	if seguidor is PathFollow3D:
		seguidor.progress += velocidade * delta
		if seguidor.progress_ratio >= 0.99:
			print("Inimigo chegou na base!")
			seguidor.queue_free() 
