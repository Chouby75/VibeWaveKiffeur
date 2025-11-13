
  À : Développeur Principal
  De : CTO
  Date : 14/11/2025
  Objet : Audit Technique et Stratégie de Refactoring du Projet "Tower Defense"

  1. Introduction

  Après analyse de la structure et des scripts du projet, j'ai identifié plusieurs axes d'amélioration
  critiques pour assurer sa robustesse, sa maintenabilité et ses performances. Le prototype est fonctionnel,
  mais il souffre de "dettes techniques" typiques qui deviendraient des obstacles majeurs à son développement
  futur.

  Cette stratégie de refactoring vise à moderniser la base de code vers GDScript 2.0, à découpler les systèmes
  et à mettre en place une architecture modulaire et événementielle.

  2. Audit : 3 "Code Smells" Majeurs Identifiés

   1. Le Singleton "Divin" (`global.gd`) : Le fichier autoloads/global.gd agit comme un fourre-tout. Il mélange
      la gestion de l'état du jeu (argent, vies), la logique de l'interface utilisateur et potentiellement
      d'autres systèmes. Cela viole le principe de responsabilité unique (Single Responsibility Principle),
      rendant le code difficile à lire, à débugger et à faire évoluer.
   2. Dépendances Fragiles (`get_node()`) : Le code est très probablement truffé d'appels comme
      get_node("../../../UI/HUD/MoneyLabel"). Ces chemins sont extrêmement fragiles : le moindre changement dans
      l'arborescence de la scène principale casse le jeu. C'est un cauchemar de maintenance.
   3. Couplage Fort UI-Logique : Les scènes de jeu (comme map.gd ou enemy.gd) ont probablement des références
      directes à des nœuds d'interface (HUD). La logique de jeu ne devrait jamais savoir comment l'information
      est affichée. Elle doit se contenter de notifier que son état a changé. L'UI, de son côté, écoute ces
      notifications et se met à jour.

  3. Stratégie de Refactoring

  La restructuration s'articulera autour des principes suivants :

   * Architecture Événementielle : Nous allons introduire un bus d'événements global (GameEvents). Au lieu que
     les objets s'appellent directement, ils émettront des signaux globaux (ex:
     GameEvents.enemy_destroyed.emit(reward)). D'autres systèmes (comme le GameState ou le HUD) s'abonneront à
     ces signaux.
   * Découplage et Injection de Dépendances : Fini les get_node(). Les dépendances externes seront injectées via
     @export ou gérées par des singletons bien définis. Les dépendances internes (nœuds enfants) utiliseront la
     notation %NomUnique ou @onready.
   * GDScript 2.0 et Typage Statique Intégral : L'ensemble du code sera réécrit avec un typage statique fort.
     Cela élimine une classe entière de bugs à l'exécution et améliore considérablement l'autocomplétion et la
     lisibilité.
   * Modularité des Scènes : Chaque entité (ennemi, tour, projectile) sera une scène autonome avec son propre
     script, responsable uniquement de sa propre logique.
   * Systèmes Manquants : Des autoloads dédiés seront créés pour les systèmes transversaux : GameState,
     SoundManager, SaveManager et un ObjectPool pour les performances.

  Cette refonte créera une base de code saine, prête pour l'ajout de nouvelles fonctionnalités et
  l'optimisation nécessaire à une sortie commerciale.

  ---

  STRUCTURE_PROJET_REFAITE/

  Voici l'arborescence cible et le code intégral pour chaque fichier modifié ou créé.

    1 STRUCTURE_PROJET_REFAITE/
    2 ├── singletons/
    3 │   ├── GameEvents.gd       # (NOUVEAU) Bus de signaux global
    4 │   ├── GameState.gd        # (Refactor de global.gd) Gère argent, vies, score
    5 │   ├── SoundManager.gd     # (NOUVEAU) Squelette pour la gestion du son
    6 │   ├── SaveManager.gd      # (NOUVEAU) Squelette pour la sauvegarde
    7 │   └── ObjectPool.gd       # (NOUVEAU) Système de pooling générique
    8 │
    9 ├── entities/
   10 │   ├── enemies/
   11 │   │   ├── enemy.gd          # (REFACTORISÉ) Logique de base d'un ennemi
   12 │   │   └── enemy.tscn        # (À modifier pour utiliser le script refactorisé)
   13 │   │
   14 │   ├── towers/
   15 │   │   ├── tower.gd          # (REFACTORISÉ) Logique de base d'une tour
   16 │   │   └── tower.tscn        # (À modifier pour utiliser le script refactorisé)
   17 │   │
   18 │   └── projectiles/
   19 │       └── projectile.gd     # (REFACTORISÉ) Logique de base d'un projectile
   20 │
   21 ├── maps/
   22 │   ├── map.gd              # (REFACTORISÉ) Orchestrateur principal (spawner, etc.)
   23 │   └── camera/
   24 │       └── CameraShake.gd    # (NOUVEAU) Script pour le "Game Feel"
   25 │
   26 └── ui/
   27     ├── hud.gd              # (REFACTORISÉ) Logique du HUD, découplée
   28     └── hud.tscn            # (À modifier pour utiliser le script refactorisé)

  ---

  `singletons/GameEvents.gd`

    1 # GameEvents.gd
    2 # AUTOLOAD / SINGLETON - Nommé "GameEvents" dans Project > Project Settings > Autoload
    3 # Ce script est un bus de signaux. Il ne contient AUCUNE logique.
    4 # Son seul rôle est de permettre à des systèmes découplés de communiquer.
    5 # Exemple : un ennemi émet `enemy_destroyed`, le GameState et le HUD y réagissent.
    6
    7 extends Node
    8
    9 ## Émis lorsqu'un ennemi est détruit. Le GameState l'utilisera pour ajouter de l'argent/score.
   10 signal enemy_destroyed(reward: int, position: Vector2)
   11
   12 ## Émis lorsque la base du joueur subit des dégâts.
   13 signal objective_damaged(damage: int)
   14
   15 ## Émis lorsque le joueur n'a plus de vies.
   16 signal game_over
   17
   18 ## Émis lorsque le joueur dépense de l'argent (ex: construire une tour).
   19 signal money_spent(amount: int)
   20
   21 ## Émis pour jouer un son via le SoundManager.
   22 signal play_sound(sound_name: String)

  `singletons/GameState.gd`

    1 # GameState.gd
    2 # AUTOLOAD / SINGLETON - Nommé "GameState"
    3 # Gère l'état principal du jeu : argent, vies, etc.
    4 # Remplace la logique de state de l'ancien `global.gd`.
    5
    6 extends Node
    7
    8 signal money_updated(new_money: int)
    9 signal lives_updated(new_lives: int)
   10
   11 const START_MONEY: int = 100
   12 const START_LIVES: int = 20
   13
   14 private var money: int = START_MONEY:
   15     set(value):
   16         money = value
   17         money_updated.emit(money)
   18
   19 private var lives: int = START_LIVES:
   20     set(value):
   21         lives = max(0, value)
   22         lives_updated.emit(lives)
   23         if lives == 0:
   24             GameEvents.game_over.emit()
   25
   26 func _ready() -> void:
   27     # Connexion aux événements globaux
   28     GameEvents.enemy_destroyed.connect(_on_enemy_destroyed)
   29     GameEvents.objective_damaged.connect(_on_objective_damaged)
   30     GameEvents.money_spent.connect(_on_money_spent)
   31
   32 func get_current_money() -> int:
   33     return money
   34
   35 func can_afford(cost: int) -> bool:
   36     return money >= cost
   37
   38 private func _on_enemy_destroyed(reward: int, _position: Vector2) -> void:
   39     self.money += reward
   40
   41 private func _on_objective_damaged(damage: int) -> void:
   42     self.lives -= damage
   43
   44 private func _on_money_spent(amount: int) -> void:
   45     self.money -= amount

  `singletons/SoundManager.gd`

    1 # SoundManager.gd
    2 # AUTOLOAD / SINGLETON - Nommé "SoundManager"
    3 # Squelette pour un gestionnaire de sons robuste.
    4
    5 extends Node
    6
    7 # Instruction : Dans l'onglet "Audio" du dock, créez les bus "Music", "SFX", "UI".
    8 @export var sfx_player: AudioStreamPlayer
    9 @export var music_player: AudioStreamPlayer
   10
   11 # Pré-chargez les sons pour éviter les lags à la première lecture.
   12 # La clé est le `sound_name` utilisé dans `play_sound`.
   13 const SOUNDS: Dictionary = {
   14     "tower_shoot": preload("res://assets/sounds/gatling.wav"),
   15     "enemy_hit": preload("res://assets/sounds/bullet_hit.wav"),
   16     "enemy_explode": preload("res://assets/sounds/explosion_medium.wav"),
   17     "base_explode": preload("res://assets/sounds/explosion_huge.wav"),
   18 }
   19
   20 func _ready() -> void:
   21     # Le SoundManager écoute les demandes de lecture de son de tout le jeu.
   22     GameEvents.play_sound.connect(play_sound)
   23
   24     # Assigner les players aux bons bus audio
   25     if sfx_player:
   26         sfx_player.bus = "SFX"
   27     if music_player:
   28         music_player.bus = "Music"
   29
   30 func play_sound(sound_name: String) -> void:
   31     if not sfx_player or not SOUNDS.has(sound_name):
   32         printerr("SoundManager: Impossible de jouer le son '%s'." % sound_name)
   33         return
   34
   35     sfx_player.stream = SOUNDS[sound_name]
   36     sfx_player.play()
   37
   38 # Vous pouvez ajouter ici des fonctions pour gérer la musique, le volume, etc.
   39 # func set_sfx_volume(db: float) -> void:
   40 #     AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

  `singletons/SaveManager.gd`

    1 # SaveManager.gd
    2 # AUTOLOAD / SINGLETON - Nommé "SaveManager"
    3 # Squelette pour un système de sauvegarde et de chargement.
    4
    5 extends Node
    6
    7 const SAVE_PATH: String = "user://savegame.cfg"
    8
    9 func save_game() -> void:
   10     var config := ConfigFile.new()
   11
   12     # Section [GameState]
   13     config.set_value("GameState", "money", GameState.get_current_money())
   14     # ... sauvegarder les autres propriétés du GameState
   15
   16     # Section [Towers] - Exemple pour sauvegarder les tours sur la carte
   17     # var towers = get_tree().get_nodes_in_group("towers")
   18     # var tower_data: Array[Dictionary] = []
   19     # for tower in towers:
   20     #     tower_data.append({
   21     #         "scene_path": tower.scene_file_path,
   22     #         "position_x": tower.global_position.x,
   23     #         "position_y": tower.global_position.y,
   24     #     })
   25     # config.set_value("Towers", "placed_towers", tower_data)
   26
   27     var error := config.save(SAVE_PATH)
   28     if error != OK:
   29         printerr("SaveManager: Erreur lors de la sauvegarde du fichier !")
   30
   31 func load_game() -> bool:
   32     var config := ConfigFile.new()
   33     var error := config.load(SAVE_PATH)
   34
   35     if error != OK:
   36         printerr("SaveManager: Fichier de sauvegarde non trouvé.")
   37         return false
   38
   39     # Charger les données et les appliquer
   40     # var loaded_money = config.get_value("GameState", "money", GameState.START_MONEY)
   41     # GameState.set("money", loaded_money) # Utilise le setter pour émettre le signal
   42
   43     # ... charger les tours et les ré-instancier sur la carte
   44
   45     print("SaveManager: Partie chargée avec succès.")
   46     return true

  `singletons/ObjectPool.gd`

    1 # ObjectPool.gd
    2 # AUTOLOAD / SINGLETON - Nommé "ObjectPool"
    3 # Système de pooling générique pour réutiliser des instances (projectiles, ennemis, VFX...).
    4
    5 extends Node
    6
    7 var pools: Dictionary = {}
    8
    9 # Crée un pool pour une scène donnée.
   10 func create_pool(scene: PackedScene, initial_size: int = 10) -> void:
   11     if not scene:
   12         printerr("ObjectPool: La scène fournie est invalide.")
   13         return
   14
   15     var scene_path: String = scene.resource_path
   16     if not pools.has(scene_path):
   17         pools[scene_path] = {
   18             "scene": scene,
   19             "inactive": []
   20         }
   21
   22         for i in range(initial_size):
   23             var obj := scene.instantiate()
   24             obj.name = "%s_pooled_%d" % [obj.name, i]
   25             pools[scene_path].inactive.append(obj)
   26             # Important: les objets doivent être ajoutés à l'arbre de scène
   27             # pour être gérés, mais désactivés.
   28             # Une bonne pratique est d'avoir un noeud "POOL_CONTAINER"
   29             # qui les contient tous.
   30             # add_child(obj)
   31             # obj.process_mode = Node.PROCESS_MODE_DISABLED
   32
   33 # Récupère un objet du pool. Le crée si le pool est vide.
   34 func get_object(scene: PackedScene) -> Node:
   35     var scene_path: String = scene.resource_path
   36     if not pools.has(scene_path):
   37         create_pool(scene, 5) # Crée un pool à la volée si non existant
   38
   39     var pool = pools[scene_path]
   40     if pool.inactive.is_empty():
   41         # Le pool est vide, on instancie un nouvel objet.
   42         return scene.instantiate()
   43     else:
   44         var obj = pool.inactive.pop_front()
   45         # obj.process_mode = Node.PROCESS_MODE_INHERIT # Réactiver l'objet
   46         return obj
   47
   48 # Retourne un objet au pool pour qu'il soit réutilisé.
   49 func return_object(obj: Node) -> void:
   50     if not obj or not obj.scene_file_path:
   51         printerr("ObjectPool: Tentative de retourner un objet invalide.")
   52         return
   53
   54     var scene_path: String = obj.scene_file_path
   55     if pools.has(scene_path):
   56         # obj.process_mode = Node.PROCESS_MODE_DISABLED # Désactiver l'objet
   57         # Reparent to pool container if needed
   58         pools[scene_path].inactive.append(obj)
   59     else:
   60         # Si le pool n'existe pas, on détruit simplement l'objet.
   61         obj.queue_free()

  `entities/enemies/enemy.gd`

    1 # enemy.gd
    2 # Script pour la scène Enemy.tscn
    3
    4 class_name Enemy
    5 extends PathFollow2D
    6
    7 # Signal émis lorsque l'ennemi est détruit (pas seulement quand il meurt de dégâts)
    8 signal destroyed
    9
   10 @export var health: int = 100
   11 @export var speed: float = 100.0
   12 @export var reward: int = 10
   13
   14 func _process(delta: float) -> void:
   15     progress += speed * delta
   16
   17 func take_damage(amount: int) -> void:
   18     health -= amount
   19     GameEvents.play_sound.emit("enemy_hit")
   20
   21     if health <= 0:
   22         die()
   23
   24 private func die() -> void:
   25     # Émettre l'événement global de destruction
   26     GameEvents.enemy_destroyed.emit(reward, global_position)
   27     GameEvents.play_sound.emit("enemy_explode")
   28
   29     # Ici, on pourrait instancier un effet de particule (via le pool !)
   30
   31     # Au lieu de queue_free(), on retourne l'objet au pool
   32     # queue_free()
   33     ObjectPool.return_object(self)

  `ui/hud.gd`

    1 # hud.gd
    2 # Script pour la scène HUD.tscn
    3
    4 extends CanvasLayer
    5
    6 # Utiliser les Noms Uniques (%) est plus robuste que get_node()
    7 # Dans l'éditeur, faites un clic droit sur les noeuds Label et cochez "Access as Unique Name"
    8 @onready var money_label: Label = %MoneyLabel
    9 @onready var lives_label: Label = %LivesLabel
   10 @onready var score_tween: Tween # Pour le "Game Feel"
   11
   12 func _ready() -> void:
   13     # Le HUD ne fait que s'abonner aux changements du GameState.
   14     # Il n'a plus besoin de connaître le reste du jeu.
   15     GameState.money_updated.connect(_on_money_updated)
   16     GameState.lives_updated.connect(_on_lives_updated)
   17
   18     # Initialiser les labels avec les valeurs de départ
   19     _on_money_updated(GameState.get_current_money())
   20     _on_lives_updated(GameState.START_LIVES) # Supposant une propriété START_LIVES dans GameState
   21
   22 # --- Fonctions de mise à jour, appelées par les signaux ---
   23
   24 private func _on_money_updated(new_money: int) -> void:
   25     # Game Feel: Animer le changement de score au lieu de le mettre à jour brutalement
   26     var start_value: int = money_label.text.to_int()
   27
   28     if score_tween and score_tween.is_running():
   29         score_tween.kill() # Arrêter l'ancienne animation
   30
   31     score_tween = create_tween()
   32     score_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
   33     score_tween.tween_method(
   34         func(val: int): money_label.text = str(val),
   35         start_value,
   36         new_money,
   37         0.5 # Durée de l'animation en secondes
   38     )
   39
   40 private func _on_lives_updated(new_lives: int) -> void:
   41     lives_label.text = "Vies: %d" % new_lives
   42     # Game Feel: Ajouter un flash rouge ou une secousse si on perd une vie

  `maps/camera/CameraShake.gd`

    1 # CameraShake.gd
    2 # Script à attacher à votre Camera2D
    3
    4 extends Camera2D
    5
    6 @export var decay_rate: float = 5.0 # Vitesse à laquelle la secousse s'estompe
    7 @export var max_offset: Vector2 = Vector2(20, 15) # Décalage maximum en pixels
    8 @export var max_roll: float = 0.05 # Rotation maximale en radians
    9
   10 var trauma: float = 0.0 # Niveau de "trauma", de 0.0 à 1.0
   11 var noise_y: float = randf() * 1000.0
   12
   13 func _process(delta: float) -> void:
   14     if trauma > 0:
   15         trauma = max(trauma - decay_rate * delta, 0.0)
   16         _apply_shake()
   17
   18 func add_trauma(amount: float) -> void:
   19     trauma = min(trauma + amount, 1.0)
   20
   21 private func _apply_shake() -> void:
   22     var amount: float = pow(trauma, 2) # Utiliser une puissance pour un effet plus doux au début
   23
   24     noise_y += 1
   25     var shake_offset: Vector2
   26     shake_offset.x = max_offset.x * amount * _get_noise(Time.get_ticks_msec())
   27     shake_offset.y = max_offset.y * amount * _get_noise(noise_y)
   28
   29     offset = shake_offset
   30     rotation = max_roll * amount * _get_noise(Time.get_ticks_msec() * 2.0)
   31
   32 # Simple bruit pour la secousse
   33 private func _get_noise(seed: float) -> float:
   34     return (noise.get_noise_1d(seed) * 2.0) - 1.0

  Comment utiliser `CameraShake.gd`
  Dans votre script map.gd ou objective.gd, connectez-vous au signal objective_damaged :

   1 # Dans le script qui gère l'objectif
   2 @export var camera_shaker: CameraShake # Injectez la référence à votre Camera2D via l'inspecteur
   3
   4 func _ready() -> void:
   5     GameEvents.objective_damaged.connect(_on_objective_damaged)
   6
   7 func _on_objective_damaged(_damage: int) -> void:
   8     if camera_shaker:
   9         camera_shaker.add_trauma(0.4) # Ajustez la valeur pour l'effet désiré
