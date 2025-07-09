@tool
extends EditorScript

# Script para criar animações placeholder para o PlayerAnimationController
# Execute via Tools > Execute Script

func _run():
	print("=== Creating Placeholder Animations ===")
	
	# Buscar o AnimationPlayer na cena atual
	var selected = EditorInterface.get_selection().get_selected_nodes()
	if selected.is_empty():
		print("❌ Selecione um nó Player3D_Modular na cena primeiro!")
		return
	
	var player = selected[0]
	var animation_player = player.get_node_or_null("AnimationPlayer")
	
	if not animation_player:
		print("❌ AnimationPlayer não encontrado! Crie um primeiro.")
		return
	
	print("✅ AnimationPlayer encontrado: %s" % animation_player.get_path())
	
	# Lista de animações essenciais
	var animations = {
		"idle": {"duration": 2.0, "loop": true},
		"run": {"duration": 1.0, "loop": true},
		"sprint": {"duration": 0.8, "loop": true},
		"jump_start": {"duration": 0.3, "loop": false},
		"jump_loop": {"duration": 1.0, "loop": true},
		"fall_loop": {"duration": 1.0, "loop": true},
		"landing_soft": {"duration": 0.3, "loop": false},
		"landing_hard": {"duration": 0.5, "loop": false},
		"kick": {"duration": 0.6, "loop": false},
		"kick_running": {"duration": 0.5, "loop": false},
		"kick_air": {"duration": 0.7, "loop": false},
		"kick_power": {"duration": 0.8, "loop": false},
		"celebration_fist_pump": {"duration": 2.0, "loop": false},
		"celebration_slide": {"duration": 1.5, "loop": false},
		"celebration_backflip": {"duration": 1.0, "loop": false},
		"slide": {"duration": 0.8, "loop": false},
		"turn": {"duration": 0.4, "loop": false},
		"recovery": {"duration": 0.5, "loop": false}
	}
	
	var created_count = 0
	
	# Criar animações placeholder
	for anim_name in animations.keys():
		if animation_player.has_animation(anim_name):
			print("⚠️  Animação '%s' já existe - pulando" % anim_name)
			continue
		
		var anim_data = animations[anim_name]
		var animation = Animation.new()
		animation.length = anim_data.duration
		animation.loop_mode = Animation.LOOP_LINEAR if anim_data.loop else Animation.LOOP_NONE
		
		# Adicionar uma track básica para o PlayerModel (posição)
		var track_index = animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track_index, "PlayerModel")
		
		# Keyframes básicos
		animation.track_insert_key(track_index, 0.0, Vector3.ZERO)
		animation.track_insert_key(track_index, anim_data.duration, Vector3.ZERO)
		
		# Para animações específicas, adicionar movimento básico
		match anim_name:
			"run", "sprint":
				# Pequeno bounce vertical
				animation.track_insert_key(track_index, anim_data.duration * 0.25, Vector3(0, 0.05, 0))
				animation.track_insert_key(track_index, anim_data.duration * 0.75, Vector3(0, 0.05, 0))
			
			"jump_start":
				animation.track_insert_key(track_index, anim_data.duration, Vector3(0, 0.2, 0))
			
			"jump_loop":
				animation.track_insert_key(track_index, anim_data.duration * 0.5, Vector3(0, 0.3, 0))
			
			"fall_loop":
				animation.track_insert_key(track_index, anim_data.duration * 0.5, Vector3(0, -0.1, 0))
			
			"landing_hard":
				animation.track_insert_key(track_index, 0.1, Vector3(0, -0.2, 0))
				animation.track_insert_key(track_index, 0.3, Vector3(0, -0.05, 0))
			
			"kick", "kick_running", "kick_power":
				# Movimento para frente no chute
				animation.track_insert_key(track_index, anim_data.duration * 0.3, Vector3(0, 0, 0.1))
			
			"celebration_fist_pump":
				animation.track_insert_key(track_index, 0.5, Vector3(0, 0.1, 0))
				animation.track_insert_key(track_index, 1.0, Vector3(0, 0.2, 0))
				animation.track_insert_key(track_index, 1.5, Vector3(0, 0.1, 0))
		
		# Adicionar animação ao player
		animation_player.add_animation_library("default", AnimationLibrary.new())
		var library = animation_player.get_animation_library("default")
		library.add_animation(anim_name, animation)
		
		print("✅ Criada animação placeholder: %s (%.1fs)" % [anim_name, anim_data.duration])
		created_count += 1
	
	print("\n=== Resumo ===")
	print("✅ %d animações criadas com sucesso!" % created_count)
	print("⚠️  Estas são apenas placeholders - substitua por animações reais!")
	print("🎮 O PlayerAnimationController já pode ser testado!")
	
	# Salvar a cena
	EditorInterface.save_scene()
	print("💾 Cena salva automaticamente")

# Função auxiliar para criar keyframes de rotação
func _add_rotation_track(animation: Animation, path: String, rotations: Array):
	var track_index = animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.track_set_path(track_index, path)
	
	for i in range(rotations.size()):
		var time = (animation.length / float(rotations.size() - 1)) * i
		animation.track_insert_key(track_index, time, rotations[i])
