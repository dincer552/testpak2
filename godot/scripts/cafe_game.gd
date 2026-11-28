extends Node3D

# Sunny Sip Bar — gerçek 3D sahil kafesi.
# Karakterler, masalar, bardaklar ve kafe sahnesi hacimli 3D mesh'lerden üretilir.

const DRINKS := [
    {"name":"Limonata","short":"LİMONATA","price":38,"color":"#F7D64A","recipe":[1,0,5],"cup":0},
    {"name":"Çilek Fizz","short":"ÇİLEK FIZZ","price":52,"color":"#F36F91","recipe":[2,0,10,5],"cup":1},
    {"name":"Buzlu Kahve","short":"BUZLU KAHVE","price":58,"color":"#9A684D","recipe":[3,4,0,12],"cup":2},
    {"name":"Tropik Rüya","short":"TROPİK RÜYA","price":66,"color":"#FF9F45","recipe":[6,7,8,0,10],"cup":3},
    {"name":"Mango Sunset","short":"MANGO SUNSET","price":72,"color":"#FFB13A","recipe":[9,6,0,5],"cup":4},
    {"name":"Orman Meyvesi","short":"ORMAN MEYVESİ","price":75,"color":"#7665B4","recipe":[11,2,13,0],"cup":0},
    {"name":"Karamel Latte","short":"KARAMEL LATTE","price":68,"color":"#B97D4A","recipe":[3,4,14,12,15],"cup":1},
    {"name":"Şeftali Ice Tea","short":"ŞEFTALİ TEA","price":54,"color":"#F4AB85","recipe":[16,17,0,5],"cup":2},
    {"name":"Yeşil Detox","short":"YEŞİL DETOX","price":62,"color":"#6BBE82","recipe":[18,1,5,0,13],"cup":3},
    {"name":"Çikolata Shake","short":"ÇİKOLATA SHAKE","price":78,"color":"#663C37","recipe":[19,4,15,12,2,0],"cup":4},
    {"name":"Ananas Mojito","short":"ANANAS MOJITO","price":70,"color":"#65CAA4","recipe":[7,13,5,0,10],"cup":0},
    {"name":"Kırmızı Velvet","short":"KIRMIZI VELVET","price":95,"color":"#BA4664","recipe":[2,11,4,15,14,0],"cup":1}
]

const INGREDIENTS := [
    {"name":"Buz","color":"#9DE0FF","buy":28},
    {"name":"Limon","color":"#FFDD53","buy":34},
    {"name":"Çilek","color":"#F15B84","buy":46},
    {"name":"Kahve","color":"#704F3E","buy":52},
    {"name":"Süt","color":"#FFF4DC","buy":38},
    {"name":"Nane","color":"#43B378","buy":25},
    {"name":"Portakal","color":"#FF9D37","buy":42},
    {"name":"Ananas","color":"#F7BE5B","buy":49},
    {"name":"Hindistan cevizi","color":"#ECEFE1","buy":55},
    {"name":"Mango","color":"#FFAB42","buy":58},
    {"name":"Soda","color":"#6FCBDC","buy":30},
    {"name":"Yaban mersini","color":"#5C70BE","buy":62},
    {"name":"Vanilya","color":"#E8BE8B","buy":44},
    {"name":"Lime","color":"#6BBE82","buy":33},
    {"name":"Karamel","color":"#B77741","buy":48},
    {"name":"Krema","color":"#FFE7D5","buy":51},
    {"name":"Şeftali","color":"#F4AE80","buy":40},
    {"name":"Çay","color":"#A05B3D","buy":36},
    {"name":"Salatalık","color":"#74BE6F","buy":29},
    {"name":"Çikolata","color":"#5B3935","buy":57}
]

const TABLE_X := [-4.2,-1.4,1.4,4.2]
const TABLE_Z := 0.35
const CUSTOMER_NAMES := ["Mina","Aras","Lara","Deniz","Emir","Ela","Mert","Ada","Ege","Defne","Can","Nil"]
const SHIRT_COLORS := ["#F47E72","#55AB91","#678FD8","#F3BE51","#A77AC8","#54A8C4","#E68F52"]
const SKIN_COLORS := ["#E0A477","#BE7B53","#F5C497","#85553E","#D99A76"]
const HAIR_COLORS := ["#493329","#704B38","#2F2928","#A26A3C","#342B3B"]

var _rng := RandomNumberGenerator.new()
var _materials: Dictionary = {}
var _tables: Array[Node3D] = []
var _table_busy: Array[bool] = [false,false,false,false]
var _customers: Array[Dictionary] = []
var _next_customer_id := 1
var _spawn_timer := 1.0
var _selected_customer_id := -1
var _cash := 4000
var _rating := 5.0
var _level := 1
var _served := 0
var _combo := 0
var _stock: Array[int] = []
var _recipe_step := 0
var _quality := 100
var _mixed := false
var _bar_closed := false
var _scene_time := 0.0
var _ui_timer := 0.0
var _message_timer := 0.0
var _message := "Sahil kafene hoş geldin! Bir sipariş seç."

var _camera: Camera3D
var _ui_root: Control
var _header_cash: Label
var _header_rating: Label
var _header_level: Label
var _orders_box: HBoxContainer
var _recipe_label: Label
var _quality_bar: ProgressBar
var _status_label: Label
var _stock_grid: GridContainer
var _mix_button: Button
var _serve_button: Button
var _closed_panel: PanelContainer

func _ready() -> void:
    _rng.randomize()
    _stock.resize(INGREDIENTS.size())
    _stock.fill(40)
    _build_environment()
    _build_tables()
    _build_hud()
    for i in range(3):
        _spawn_customer()
    _refresh_hud()

func _process(delta: float) -> void:
    _scene_time += delta
    _message_timer = maxf(0.0,_message_timer-delta)
    if not _bar_closed and _customers.size()<4:
        _spawn_timer -= delta
        if _spawn_timer<=0.0:
            _spawn_customer()
            _spawn_timer=2.0
    _update_customers(delta)
    _update_water_and_decor()
    _ui_timer -= delta
    if _ui_timer<=0.0:
        _ui_timer=0.35
        _refresh_hud()

# WORLD, CAMERA AND LIGHTING

func _build_environment() -> void:
    var world:=WorldEnvironment.new()
    var environment:=Environment.new()
    environment.background_mode=Environment.BG_COLOR
    environment.background_color=Color("#83D8EC")
    environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color=Color("#FFE5C4")
    environment.ambient_light_energy=0.72
    environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
    world.environment=environment
    add_child(world)

    var sun:=DirectionalLight3D.new()
    sun.name="WarmIslandSun"
    sun.rotation_degrees=Vector3(-48,-28,0)
    sun.light_color=Color("#FFF0D4")
    sun.light_energy=1.25
    sun.shadow_enabled=true
    add_child(sun)

    var fill:=OmniLight3D.new()
    fill.position=Vector3(0,7,2)
    fill.light_color=Color("#9AD8F5")
    fill.light_energy=0.38
    fill.omni_range=22.0
    add_child(fill)

    _camera=Camera3D.new()
    _camera.name="IsometricCafeCamera"
    _camera.projection=Camera3D.PROJECTION_ORTHOGONAL
    _camera.size=23.5
    _camera.position=Vector3(0,10.5,14.5)
    _camera.look_at(Vector3(0,1.1,-1.65),Vector3.UP)
    _camera.current=true
    add_child(_camera)

    var ocean:=PlaneMesh.new()
    ocean.size=Vector2(28,12)
    _add_mesh(self,"TurquoiseSea",ocean,_mat("#53C4D5",0.28),Vector3(0,-0.40,-11.5))
    var sand:=PlaneMesh.new()
    sand.size=Vector2(23,19)
    _add_mesh(self,"WarmBeach",sand,_mat("#F4D49A"),Vector3(0,-0.31,-1.2))

    _make_box(self,"WoodenCafeDeck",Vector3(12.4,0.34,11.8),Vector3(0,-0.10,-1.0),_mat("#B97849"))
    for i in range(26):
        var z:float=-6.7+float(i)*0.43
        var tone:String="#C88A58" if i%2==0 else "#B97949"
        _make_box(self,"DeckPlank_%02d"%i,Vector3(12.1,0.018,0.37),Vector3(0,0.083,z),_mat(tone))
    _make_box(self,"FrontDeckTrim",Vector3(12.5,0.22,0.18),Vector3(0,-0.05,4.88),_mat("#895333"))

    for i in range(8):
        var wave:=_make_box(self,"SeaGlint_%02d"%i,Vector3(9.0+float(i%3),0.025,0.035),
            Vector3(-0.4,-0.17,-9.4-float(i)*0.35),_mat("#B5EEF0",0.25))
        wave.set_meta("wave_phase",float(i)*0.9)

    _build_cafe_hut()
    _build_palm(Vector3(-5.7,0,-3.4),1.05)
    _build_palm(Vector3(5.75,0,-3.3),0.90)
    _build_palm(Vector3(-6.1,0,2.7),0.74)
    _build_palm(Vector3(6.1,0,2.9),0.78)
    _make_decor()
    _make_box(self,"PathRunner",Vector3(10.4,0.03,1.55),Vector3(0,0.11,3.05),_mat("#E9C28D"))

func _build_cafe_hut() -> void:
    _make_box(self,"CafeBackWall",Vector3(10.3,3.35,0.42),Vector3(0,1.63,-6.65),_mat("#FFEBCB"))
    _make_box(self,"CafeWallLowerTrim",Vector3(10.4,0.22,0.5),Vector3(0,0.28,-6.38),_mat("#D79A65"))
    _make_box(self,"CafeWindow",Vector3(5.3,1.45,0.08),Vector3(-1.0,2.05,-6.39),_mat("#6ABCC2",0.25))
    _make_box(self,"CafeWindowFrameTop",Vector3(5.55,0.10,0.16),Vector3(-1.0,2.82,-6.27),_mat("#FFF5D9"))
    _make_box(self,"CafeWindowFrameLeft",Vector3(0.12,1.55,0.16),Vector3(-3.72,2.08,-6.27),_mat("#FFF5D9"))
    _make_box(self,"CafeWindowFrameRight",Vector3(0.12,1.55,0.16),Vector3(1.72,2.08,-6.27),_mat("#FFF5D9"))
    _make_box(self,"CafeWindowDivider",Vector3(0.10,1.45,0.18),Vector3(-1.0,2.05,-6.24),_mat("#FFF5D9"))
    _make_box(self,"CafeDoor",Vector3(1.55,2.45,0.12),Vector3(3.48,1.25,-6.34),_mat("#B9794E"))
    _make_box(self,"CafeDoorGlass",Vector3(1.17,1.35,0.06),Vector3(3.48,1.62,-6.24),_mat("#94DDE0",0.22))
    _make_box(self,"CafeSignBoard",Vector3(4.6,0.65,0.18),Vector3(0,3.18,-6.16),_mat("#FFF7DE"))
    _make_label_in_world(Vector3(0,3.18,-6.04),"SUNNY SIP",Color("#657A53"),0.50)

    var stripe_colors:=["#F47F72","#F5D36C","#F47F72","#F5D36C","#F47F72","#F5D36C","#F47F72"]
    for i in range(7):
        var x:float=-4.55+float(i)*1.52
        _make_box(self,"AwningStripe_%d"%i,Vector3(1.48,0.22,1.55),Vector3(x,3.42,-5.72),_mat(stripe_colors[i]))
        _make_sphere(self,"AwningScallop_%d"%i,Vector3(x,3.30,-4.96),0.42,_mat(stripe_colors[i]),Vector3(1.75,0.42,0.52))
    _make_box(self,"AwningCanopy",Vector3(10.8,0.12,1.72),Vector3(0,3.56,-5.72),_mat("#FFF4D4"))

    _make_box(self,"BarCounterBody",Vector3(9.8,0.92,0.92),Vector3(0,0.58,-4.55),_mat("#9D603D"))
    _make_box(self,"BarCounterTop",Vector3(10.05,0.17,1.12),Vector3(0,1.10,-4.52),_mat("#E5AD73"))
    _make_box(self,"CounterFrontPanel",Vector3(8.8,0.45,0.06),Vector3(0,0.64,-4.06),_mat("#C98550"))
    for x in [-3.9,-2.1,2.1,3.9]:
        _make_box(self,"CounterDetail",Vector3(0.05,0.34,0.03),Vector3(x,0.64,-4.015),_mat("#F4D0A0"))
    _make_box(self,"CoffeeMachine",Vector3(1.15,1.05,0.78),Vector3(-3.2,1.72,-5.02),_mat("#F8EBD2",0.28))
    _make_box(self,"CoffeeMachineScreen",Vector3(0.68,0.39,0.08),Vector3(-3.2,1.85,-4.60),_mat("#4B7E7D",0.18))
    _make_box(self,"CoffeeMachineDisplay",Vector3(0.47,0.21,0.035),Vector3(-3.2,1.85,-4.55),_mat("#204A4E"))
    _make_cylinder(self,"CoffeeKnob",0.10,0.10,0.12,Vector3(-3.2,1.20,-4.57),_mat("#D4A15D"))
    _make_box(self,"JuiceDispenser",Vector3(0.85,1.25,0.78),Vector3(3.1,1.82,-5.0),_mat("#F7E8C8"))
    _make_box(self,"DispenserJuice",Vector3(0.58,0.46,0.07),Vector3(3.1,1.77,-4.57),_mat("#F9AC43"))
    for j in range(5):
        _make_sphere(self,"CounterFruit_%d"%j,Vector3(-1.5+float(j)*0.35,1.31,-4.25),0.17,
            _mat(["#EFA047","#F5D44E","#E95779","#73B879","#F5B6A1"][j]),Vector3(1.0,0.66,1.0))
    _make_box(self,"CounterMenuBoard",Vector3(1.35,0.88,0.12),Vector3(0,2.05,-5.78),_mat("#496A58"))
    _make_label_in_world(Vector3(0,2.13,-5.69),"FRESH DRINKS",Color("#FFF1D1"),0.19)

func _build_palm(position: Vector3, scale_factor: float) -> void:
    var tree:=Node3D.new()
    tree.position=position
    tree.scale=Vector3.ONE*scale_factor
    add_child(tree)
    _make_cylinder(tree,"PalmTrunk",0.14,0.26,3.0,Vector3(0,1.45,0),_mat("#9C6843"),Vector3(0,0,-0.13))
    _make_sphere(tree,"PalmCrown",Vector3(0,2.96,0),0.35,_mat("#8BBD69"),Vector3(1.15,0.75,1.0))
    for i in range(8):
        var angle:float=TAU*float(i)/8.0
        var leaf:=_make_sphere(tree,"PalmLeaf_%d"%i,Vector3(cos(angle)*0.78,2.84+sin(angle*2.0)*0.10,sin(angle)*0.78),
            0.52,_mat("#3F9D68"),Vector3(1.55,0.12,0.43))
        leaf.rotation.y=-angle
        leaf.rotation.z=-0.28
    for i in range(3):
        _make_sphere(tree,"Coconut_%d"%i,Vector3(cos(float(i)*2.1)*0.19,2.72,sin(float(i)*2.1)*0.19),
            0.14,_mat("#8A573A"))

func _make_decor() -> void:
    for i in range(5):
        var lantern:=_make_sphere(self,"CafeLantern_%d"%i,Vector3(-4.0+float(i)*2.0,3.9,-5.2),0.13,_mat("#FFD67B"))
        lantern.scale=Vector3(0.70,1.1,0.70)
    for x in [-5.5,5.5]:
        _make_cylinder(self,"FlowerPot",0.40,0.40,0.46,Vector3(x,0.28,1.7),_mat("#C67C51"))
        for i in range(5):
            var angle:float=TAU*float(i)/5.0
            _make_sphere(self,"TropicalPlant",Vector3(x+cos(angle)*0.25,0.75,1.7+sin(angle)*0.25),
                0.25,_mat("#58A56B"),Vector3(0.65,1.4,0.65))

func _build_tables() -> void:
    _tables.clear()
    for i in range(TABLE_X.size()):
        var x:float=TABLE_X[i]
        var table:=Node3D.new()
        table.name="GuestTable_%d"%i
        table.position=Vector3(x,0,TABLE_Z)
        add_child(table)
        _make_cylinder(table,"RoundWoodTop",0.70,0.70,0.17,Vector3(0,1.00,0),_mat("#E6B47A"))
        _make_cylinder(table,"TableRim",0.72,0.72,0.065,Vector3(0,0.89,0),_mat("#9A603D"))
        _make_cylinder(table,"TablePedestal",0.16,0.16,0.77,Vector3(0,0.48,0),_mat("#895536"))
        for sx in [-1.0,1.0]:
            for sz in [-1.0,1.0]:
                _make_box(table,"TableFoot",Vector3(0.13,0.10,0.13),Vector3(sx*0.43,0.06,sz*0.43),_mat("#865338"))
        _make_sphere(table,"TableFlower",Vector3(-0.22,1.13,0.02),0.12,_mat("#F4B7A7"))
        _make_sphere(table,"TableLeaf",Vector3(-0.11,1.15,0.03),0.10,_mat("#54A96E"),Vector3(1.5,0.35,0.65))
        _make_cylinder(table,"TableVase",0.10,0.10,0.25,Vector3(0.27,1.18,0.02),_mat("#8ED1D4",0.25))
        _make_chair(Vector3(x,0,TABLE_Z-0.93),i)
        _tables.append(table)

func _make_chair(pos: Vector3, id: int) -> void:
    var chair:=Node3D.new()
    chair.name="GuestChair_%d"%id
    chair.position=pos
    add_child(chair)
    _make_box(chair,"ChairSeat",Vector3(0.86,0.16,0.72),Vector3(0,0.66,0),_mat("#E9BC82"))
    _make_box(chair,"ChairBack",Vector3(0.86,0.82,0.15),Vector3(0,1.08,-0.32),_mat("#C98555"))
    for sx in [-0.32,0.32]:
        _make_box(chair,"ChairLeg",Vector3(0.11,0.63,0.11),Vector3(sx,0.32,0.0),_mat("#865338"))

func _update_water_and_decor() -> void:
    for child in get_children():
        if child is MeshInstance3D and child.has_meta("wave_phase"):
            var phase:float=float(child.get_meta("wave_phase"))
            child.position.x=-0.4+sin(_scene_time*0.62+phase)*0.35

# PROCEDURAL 3D CHARACTERS AND GLASSWARE

func _spawn_customer() -> void:
    if _bar_closed or _customers.size()>=4:
        return
    var table_id: int=-1
    for i in range(_table_busy.size()):
        if not _table_busy[i]:
            table_id=i
            break
    if table_id<0:
        return
    _table_busy[table_id]=true
    var drink_id:int=_rng.randi_range(0,DRINKS.size()-1)
    var guest_name:String=CUSTOMER_NAMES[_rng.randi_range(0,CUSTOMER_NAMES.size()-1)]
    var side:float=-1.0 if TABLE_X[table_id]<0.0 else 1.0
    var table_x:float=TABLE_X[table_id]
    var seat:=Vector3(table_x,0.0,TABLE_Z-1.02)
    var approach:=Vector3(table_x+side*1.05,0.0,TABLE_Z-1.02)
    var spawn:=Vector3(side*7.0,0.0,-3.2+float(table_id%2)*1.2)
    var model:=_create_character(guest_name)
    var root:Node3D=model["root"]
    root.position=spawn
    var customer:Dictionary={
        "id":_next_customer_id,"name":guest_name,"drink":drink_id,"table":table_id,
        "state":"arriving","patience":1.0,"anger_timer":0.0,"drink_timer":0.0,
        "anim_time":_rng.randf_range(0.0,TAU),"route":[approach,seat],"route_step":0,
        "exit_route":[],"model":model,"rejecting":false,"cup":null
    }
    _next_customer_id+=1
    _customers.append(customer)
    _message="%s kafeye geldi. %s istiyor."%[guest_name,DRINKS[drink_id]["name"]]
    _message_timer=2.2
    if _selected_customer_id<0:
        _selected_customer_id=int(customer["id"])

func _create_character(character_name: String) -> Dictionary:
    var root:=Node3D.new()
    root.name="Customer3D_"+character_name
    var shirt:=_mat(SHIRT_COLORS[_rng.randi_range(0,SHIRT_COLORS.size()-1)])
    var skin:=_mat(SKIN_COLORS[_rng.randi_range(0,SKIN_COLORS.size()-1)])
    var hair:=_mat(HAIR_COLORS[_rng.randi_range(0,HAIR_COLORS.size()-1)])
    var pants:=_mat("#55779B")
    _make_capsule(root,"SoftShirtBody",Vector3(0,0.99,0),0.32,1.02,shirt)
    _make_box(root,"ApronFront",Vector3(0.34,0.48,0.045),Vector3(0,1.00,0.315),_mat("#F4E4C6"))
    _make_capsule(root,"Neck",Vector3(0,1.48,0.02),0.12,0.27,skin)
    _make_sphere(root,"FriendlyFace",Vector3(0,1.78,0.05),0.36,skin,Vector3(1.0,1.12,0.92))
    _make_sphere(root,"SoftHair",Vector3(0,2.00,0.025),0.35,hair,Vector3(1.08,0.58,1.02))
    _make_sphere(root,"HairLock",Vector3(-0.20,1.94,0.24),0.16,hair,Vector3(1.25,0.52,0.72))
    for side in [-1.0,1.0]:
        _make_sphere(root,"Ear",Vector3(side*0.34,1.76,0.07),0.085,skin)
        _make_sphere(root,"Eye",Vector3(side*0.125,1.81,0.365),0.042,_mat("#342A25"),Vector3(0.8,1.0,0.55))
    var left_brow:=_make_box(root,"LeftEyebrow",Vector3(0.16,0.035,0.045),Vector3(-0.13,1.92,0.365),hair)
    var right_brow:=_make_box(root,"RightEyebrow",Vector3(0.16,0.035,0.045),Vector3(0.13,1.92,0.365),hair)
    var mouth:=_make_sphere(root,"Smile",Vector3(0,1.62,0.37),0.055,_mat("#8F4F48"),Vector3(1.35,0.34,0.40))
    _make_sphere(root,"CheekLeft",Vector3(-0.23,1.68,0.34),0.065,_mat("#E99A8F"),Vector3(1.3,0.8,0.25))
    _make_sphere(root,"CheekRight",Vector3(0.23,1.68,0.34),0.065,_mat("#E99A8F"),Vector3(1.3,0.8,0.25))

    var left_arm:=Node3D.new()
    left_arm.position=Vector3(-0.34,1.28,0.02)
    root.add_child(left_arm)
    _make_capsule(left_arm,"LeftArm",Vector3(0,-0.28,0.12),0.105,0.62,skin)
    _make_sphere(left_arm,"LeftHand",Vector3(0,-0.56,0.20),0.115,skin)
    var right_arm:=Node3D.new()
    right_arm.position=Vector3(0.34,1.28,0.02)
    root.add_child(right_arm)
    _make_capsule(right_arm,"RightArm",Vector3(0,-0.28,0.12),0.105,0.62,skin)
    _make_sphere(right_arm,"RightHand",Vector3(0,-0.56,0.20),0.115,skin)

    var left_leg:=Node3D.new()
    left_leg.position=Vector3(-0.15,0.56,0)
    root.add_child(left_leg)
    _make_capsule(left_leg,"LeftLeg",Vector3(0,-0.24,0),0.12,0.56,pants)
    _make_box(left_leg,"LeftShoe",Vector3(0.22,0.12,0.36),Vector3(0,-0.52,0.10),_mat("#FFF0D8"))
    var right_leg:=Node3D.new()
    right_leg.position=Vector3(0.15,0.56,0)
    root.add_child(right_leg)
    _make_capsule(right_leg,"RightLeg",Vector3(0,-0.24,0),0.12,0.56,pants)
    _make_box(right_leg,"RightShoe",Vector3(0.22,0.12,0.36),Vector3(0,-0.52,0.10),_mat("#FFF0D8"))
    add_child(root)
    return {"root":root,"left_arm":left_arm,"right_arm":right_arm,
        "left_leg":left_leg,"right_leg":right_leg,"left_brow":left_brow,
        "right_brow":right_brow,"mouth":mouth}

func _make_drink_model(drink_id: int) -> Node3D:
    var drink:Dictionary=DRINKS[drink_id]
    var model:=Node3D.new()
    model.name="ServedDrink_"+str(drink_id)
    var style:int=int(drink["cup"])
    var top_radius:float=0.17
    var bottom_radius:float=0.13
    var height:float=0.50
    if style==1:
        top_radius=0.22
        bottom_radius=0.15
        height=0.55
    elif style==2:
        top_radius=0.19
        bottom_radius=0.16
        height=0.38
    elif style==3:
        top_radius=0.16
        bottom_radius=0.11
        height=0.62
    elif style==4:
        top_radius=0.22
        bottom_radius=0.19
        height=0.48
    var glassmat:=StandardMaterial3D.new()
    glassmat.albedo_color=Color(0.92,0.97,0.96,0.62)
    glassmat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
    glassmat.roughness=0.15
    glassmat.metallic=0.08
    _make_cylinder(model,"CrystalGlass",top_radius,bottom_radius,height,Vector3.ZERO,glassmat)
    _make_cylinder(model,"ColorfulDrink",top_radius*0.91,bottom_radius*0.92,height*0.68,
        Vector3(0,-0.035,0),_mat(drink["color"],0.22))
    _make_cylinder(model,"CupBase",bottom_radius*1.12,bottom_radius*1.12,0.045,
        Vector3(0,-height*0.48,0),_mat("#FFF1D9",0.25))
    var straw:=_make_cylinder(model,"StripedStraw",0.022,0.022,height*0.48,
        Vector3(0.055,height*0.48,0.01),_mat("#FFF5DC"))
    straw.rotation.z=-0.16
    _make_sphere(model,"FruitGarnish",Vector3(-0.09,height*0.48,0.015),0.105,
        _mat(INGREDIENTS[int(drink["recipe"][0])]["color"]),Vector3(1.3,0.45,0.95))
    _make_sphere(model,"MintLeaf",Vector3(0.08,height*0.47,-0.015),0.08,_mat("#49A96D"),Vector3(1.3,0.25,0.8))
    if style==2:
        _make_sphere(model,"MugHandleTop",Vector3(0.22,0.05,0),0.095,_mat("#F9EBD5"),Vector3(0.6,0.9,0.5))
        _make_sphere(model,"MugHandleBottom",Vector3(0.22,-0.10,0),0.095,_mat("#F9EBD5"),Vector3(0.6,0.9,0.5))
    return model

# CUSTOMER WALK / WAIT / BANG / DRINK / LEAVE

func _update_customers(delta: float) -> void:
    for i in range(_customers.size()-1,-1,-1):
        var c:Dictionary=_customers[i]
        c["anim_time"]=float(c["anim_time"])+delta
        var state:String=c["state"]
        if _bar_closed and state!="leaving":
            c["state"]="leaving"
            c["exit_route"]=[Vector3(-7.5 if float(c["root"].position.x)<0.0 else 7.5,0,2.7)]
            c["route_step"]=0
            state="leaving"

        if state=="arriving":
            if _follow_route(c,delta,2.2):
                c["state"]="waiting"
                c["patience"]=1.0
                c["root"].rotation.y=0.0
                c["root"].scale=Vector3(1.0,0.88,1.0)
                _message="%s masasına oturdu. Siparişi hazırla."%c["name"]
                _message_timer=2.0
        elif state=="waiting":
            c["patience"]=maxf(0.0,float(c["patience"])-delta/25.0)
            if float(c["patience"])<0.45:
                c["state"]="angry"
                c["anger_timer"]=0.0
                _message="%s sabırsızlanmaya başladı!"%c["name"]
                _message_timer=2.0
        elif state=="angry":
            if bool(c["rejecting"]):
                c["anger_timer"]=float(c["anger_timer"])+delta
                if float(c["anger_timer"])>1.5:
                    _begin_leaving(c,true)
            else:
                c["anger_timer"]=float(c["anger_timer"])+delta
                c["patience"]=maxf(0.0,float(c["patience"])-delta/12.0)
                if float(c["anger_timer"])>3.0:
                    c["state"]="banging"
                    c["anger_timer"]=0.0
                    _message="%s masaya vurmaya başladı! Hemen servis et!"%c["name"]
                    _message_timer=2.5
        elif state=="banging":
            c["anger_timer"]=float(c["anger_timer"])+delta
            if float(c["anger_timer"])>7.0:
                _change_rating(-0.12)
                _begin_leaving(c,false)
        elif state=="drinking":
            c["drink_timer"]=float(c["drink_timer"])-delta
            if float(c["drink_timer"])<=0.0:
                _message="%s içeceğini bitirdi. Masadan kalkıyor."%c["name"]
                _message_timer=2.0
                _begin_leaving(c,false)
        elif state=="leaving":
            if _follow_route(c,delta,3.0):
                _remove_customer(i)
                continue
        _customers[i]=c
        _animate_customer(c)

func _follow_route(c: Dictionary, delta: float, speed: float) -> bool:
    var route:Array=c["exit_route"] if c["state"]=="leaving" else c["route"]
    var step:int=int(c["route_step"])
    if step>=route.size():
        return true
    var root:Node3D=c["root"]
    var target:Vector3=route[step]
    var direction:Vector3=target-root.position
    direction.y=0
    if direction.length()>0.08:
        root.position=root.position.move_toward(target,speed*delta)
        root.rotation.y=atan2(direction.x,direction.z)
        return false
    root.position=target
    c["route_step"]=step+1
    return int(c["route_step"])>=route.size()

func _animate_customer(c: Dictionary) -> void:
    var model:Dictionary=c["model"]
    var root:Node3D=model["root"]
    var phase:float=float(c["anim_time"])
    var state:String=c["state"]
    var left_arm:Node3D=model["left_arm"]
    var right_arm:Node3D=model["right_arm"]
    var left_leg:Node3D=model["left_leg"]
    var right_leg:Node3D=model["right_leg"]
    var left_brow:MeshInstance3D=model["left_brow"]
    var right_brow:MeshInstance3D=model["right_brow"]
    var mouth:MeshInstance3D=model["mouth"]

    if state=="arriving" or state=="leaving":
        root.scale=Vector3.ONE
        left_arm.rotation.z=sin(phase*8.0)*0.42
        right_arm.rotation.z=-sin(phase*8.0)*0.42
        left_leg.rotation.z=sin(phase*8.0)*0.34
        right_leg.rotation.z=-sin(phase*8.0)*0.34
        root.position.y=abs(sin(phase*8.0))*0.045
        left_brow.rotation.z=0.0
        right_brow.rotation.z=0.0
        mouth.scale.y=0.35
    elif state=="waiting":
        root.scale=Vector3(1.0,0.88,1.0)
        left_arm.rotation.z=0.0
        right_arm.rotation.z=0.0
        left_leg.rotation.z=0.0
        right_leg.rotation.z=0.0
        root.position.y=-0.10
        mouth.scale.y=0.35
    elif state=="angry" or state=="banging":
        root.position.y=-0.10+abs(sin(phase*12.0))*0.035
        left_brow.rotation.z=-0.30
        right_brow.rotation.z=0.30
        mouth.scale.y=0.90
        if state=="banging":
            var hit:float=abs(sin(phase*13.0))
            left_arm.rotation.z=1.15+hit*0.82
            right_arm.rotation.z=-1.15-hit*0.82
            var table:Node3D=_tables[int(c["table"])]
            table.rotation.z=sin(phase*26.0)*0.025
            table.position.y=abs(sin(phase*13.0))*0.035
        else:
            left_arm.rotation.z=0.12
            right_arm.rotation.z=-0.12
    elif state=="drinking":
        root.position.y=-0.10+sin(phase*4.4)*0.018
        right_arm.rotation.z=-1.25+sin(phase*4.4)*0.08
        left_arm.rotation.z=0.10
        var cup:Node3D=c["cup"]
        if is_instance_valid(cup):
            cup.position=Vector3(0.49,1.42+sin(phase*4.4)*0.025,0.40)
            cup.rotation.z=-0.14+sin(phase*4.4)*0.04
    else:
        root.position.y=-0.10

func _begin_leaving(c: Dictionary, rejected: bool) -> void:
    if c["state"]=="leaving":
        return
    c["state"]="leaving"
    c["rejecting"]=false
    var table_x:float=TABLE_X[int(c["table"])]
    var side:float=-1.0 if table_x<0.0 else 1.0
    c["exit_route"]=[Vector3(table_x+side*1.05,0,TABLE_Z-1.02),Vector3(side*7.5,0,2.6)]
    c["route_step"]=0
    var cup=c["cup"]
    if cup!=null and is_instance_valid(cup):
        cup.queue_free()
    c["cup"]=null
    if rejected:
        _message="%s içeceği reddetti ve ödeme yapmadan gidiyor."%c["name"]
        _message_timer=2.5

func _remove_customer(index: int) -> void:
    var c:Dictionary=_customers[index]
    var root:Node3D=c["root"]
    if is_instance_valid(root):
        root.queue_free()
    var table_id:int=int(c["table"])
    _table_busy[table_id]=false
    _tables[table_id].rotation=Vector3.ZERO
    _tables[table_id].position.y=0.0
    if int(c["id"])==_selected_customer_id:
        _selected_customer_id=-1
        _reset_recipe()
    _customers.remove_at(index)
    _spawn_timer=minf(_spawn_timer,1.2)

# ORDER, RECIPE, CASH AND REPUTATION

func _find_customer_index(customer_id: int) -> int:
    for i in range(_customers.size()):
        if int(_customers[i]["id"])==customer_id:
            return i
    return -1

func _customer_has_order(c: Dictionary) -> bool:
    return not bool(c["rejecting"]) and str(c["state"]) in ["waiting","angry","banging"]

func _select_order(customer_id: int) -> void:
    var index:int=_find_customer_index(customer_id)
    if index<0 or not _customer_has_order(_customers[index]):
        return
    _selected_customer_id=customer_id
    _reset_recipe()
    _message="%s • %s siparişi"%[_customers[index]["name"],DRINKS[int(_customers[index]["drink"])]["name"]]
    _message_timer=2.0
    _refresh_hud()

func _current_customer() -> Dictionary:
    var index:int=_find_customer_index(_selected_customer_id)
    if index<0:
        return {}
    if not _customer_has_order(_customers[index]):
        return {}
    return _customers[index]

func _on_ingredient_pressed(ingredient_id: int) -> void:
    if _bar_closed:
        return
    var c:Dictionary=_current_customer()
    if c.is_empty():
        _show_message("Önce üstteki sipariş kartından müşteri seç.")
        return
    if _mixed:
        _show_message("İçecek karıştırıldı. Önce servis et.")
        return
    var recipe:Array=DRINKS[int(c["drink"])]["recipe"]
    if _recipe_step>=recipe.size():
        _show_message("Malzemeler tamam. Şimdi KARIŞTIR!")
        return
    if _stock[ingredient_id]<=0:
        _show_message("%s stoğu bitti. Yanındaki + ile 10 adet al."%INGREDIENTS[ingredient_id]["name"])
        return
    var expected:int=int(recipe[_recipe_step])
    if ingredient_id!=expected:
        _quality=maxi(0,_quality-22)
        _show_message("Yanlış sıra! Şimdi %s eklemelisin. Kalite -22."%INGREDIENTS[expected]["name"])
        _refresh_hud()
        return
    _stock[ingredient_id]-=1
    _recipe_step+=1
    _show_message("%s doğru sırada eklendi."%INGREDIENTS[ingredient_id]["name"])
    _refresh_hud()

func _purchase_ingredient(ingredient_id: int) -> void:
    var price:int=int(INGREDIENTS[ingredient_id]["buy"])
    if _cash<price:
        _show_message("Yetersiz bakiye. 10 adet paket $%d."%price)
        return
    _cash-=price
    _stock[ingredient_id]+=10
    _show_message("%s stoğuna 10 adet eklendi. -$%d."%[INGREDIENTS[ingredient_id]["name"],price])
    _refresh_hud()

func _mix_drink() -> void:
    if _bar_closed:
        return
    var c:Dictionary=_current_customer()
    if c.is_empty():
        _show_message("Karıştırmadan önce bir sipariş seç.")
        return
    var recipe:Array=DRINKS[int(c["drink"])]["recipe"]
    if _recipe_step<recipe.size():
        var needed:int=int(recipe[_recipe_step])
        _quality=maxi(0,_quality-15)
        _show_message("Tarif bitmedi. Önce %s ekle. Kalite -15."%INGREDIENTS[needed]["name"])
        _refresh_hud()
        return
    _mixed=true
    _show_message("İçecek karıştırıldı. Kalite %d/100."%_quality)
    _refresh_hud()

func _serve_drink() -> void:
    if _bar_closed:
        return
    var c:Dictionary=_current_customer()
    if c.is_empty():
        _show_message("Servis için bekleyen bir müşteri seç.")
        return
    if not _mixed:
        _show_message("Önce tarif sırasını tamamla ve karıştır.")
        return
    if _quality<60:
        _combo=0
        var rejected_index:int=_find_customer_index(_selected_customer_id)
        if rejected_index>=0:
            _customers[rejected_index]["rejecting"]=true
            _customers[rejected_index]["state"]="angry"
            _customers[rejected_index]["anger_timer"]=0.0
        _change_rating(-0.15)
        _reset_recipe()
        _show_message("%s içeceği beğenmedi. Para ödemiyor!"%c["name"])
        _selected_customer_id=-1
        _refresh_hud()
        return

    var drink:Dictionary=DRINKS[int(c["drink"])]
    var payment:int=maxi(1,roundi(float(drink["price"])*float(_quality)/100.0))
    if str(c["state"])=="angry" or str(c["state"])=="banging":
        payment=maxi(1,payment-4)
    _cash+=payment
    _served+=1
    _combo+=1
    if _quality>=95 and float(c["patience"])>0.35:
        _change_rating(0.025)
    elif _quality>=80:
        _change_rating(0.012)
    else:
        _change_rating(-0.025)
    var index:int=_find_customer_index(_selected_customer_id)
    if index>=0:
        _customers[index]["state"]="drinking"
        _customers[index]["drink_timer"]=4.2
        var cup:Node3D=_make_drink_model(int(c["drink"]))
        var model:Dictionary=_customers[index]["model"]
        var root:Node3D=model["root"]
        root.add_child(cup)
        cup.position=Vector3(0.49,1.42,0.40)
        cup.scale=Vector3(0.78,0.78,0.78)
        _customers[index]["cup"]=cup
    if _served%5==0:
        _level+=1
    _show_message("%s içeceğini beğendi! +$%d • Kalite %d%%."%[c["name"],payment,_quality])
    _selected_customer_id=-1
    _reset_recipe()
    _refresh_hud()

func _change_rating(delta: float) -> void:
    if _bar_closed:
        return
    _rating=clampf(_rating+delta,0.0,5.0)
    if _rating<2.0:
        _bar_closed=true
        for i in range(_customers.size()):
            var c:Dictionary=_customers[i]
            c["state"]="leaving"
            c["rejecting"]=false
            var table_x:float=TABLE_X[int(c["table"])]
            var side:float=-1.0 if table_x<0.0 else 1.0
            c["exit_route"]=[Vector3(table_x+side*1.05,0,TABLE_Z-1.02),Vector3(side*7.5,0,2.6)]
            c["route_step"]=0
            _customers[i]=c
        _show_message("Bar puanı 2 yıldızın altına düştü. KAFE KAPANDI.")
        if _closed_panel!=null:
            _closed_panel.visible=true

func _reset_recipe() -> void:
    _recipe_step=0
    _quality=100
    _mixed=false

func _show_message(text: String) -> void:
    _message=text
    _message_timer=2.5
    if _status_label!=null:
        _status_label.text=text

# MOBILE HUD

func _build_hud() -> void:
    var layer:=CanvasLayer.new()
    layer.layer=10
    add_child(layer)
    _ui_root=Control.new()
    _ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(_ui_root)

    var header:=_panel(_ui_root,Vector2(18,18),Vector2(684,76),Color("#FFF8E7"))
    var header_row:=HBoxContainer.new()
    header_row.add_theme_constant_override("separation",14)
    header_row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    header.add_child(header_row)
    var title:=Label.new()
    title.text="SUNNY SIP BAR"
    title.add_theme_font_size_override("font_size",24)
    title.add_theme_color_override("font_color",Color("#536C4F"))
    title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    header_row.add_child(title)
    _header_level=Label.new()
    _header_level.text="LVL 1"
    _header_level.add_theme_font_size_override("font_size",16)
    _header_level.add_theme_color_override("font_color",Color("#648A6A"))
    header_row.add_child(_header_level)
    _header_rating=Label.new()
    _header_rating.text="★ 5.00"
    _header_rating.add_theme_font_size_override("font_size",19)
    _header_rating.add_theme_color_override("font_color",Color("#A97935"))
    header_row.add_child(_header_rating)
    _header_cash=Label.new()
    _header_cash.text="$4,000"
    _header_cash.add_theme_font_size_override("font_size",22)
    _header_cash.add_theme_color_override("font_color",Color("#9B663A"))
    header_row.add_child(_header_cash)

    var order_panel:=_panel(_ui_root,Vector2(18,105),Vector2(684,119),Color("#FFF9E8"))
    var order_v:=VBoxContainer.new()
    order_v.add_theme_constant_override("separation",5)
    order_panel.add_child(order_v)
    var order_title:=Label.new()
    order_title.text="MÜŞTERİ TALEPLERİ  •  SİPARİŞİ SEÇ"
    order_title.add_theme_font_size_override("font_size",15)
    order_title.add_theme_color_override("font_color",Color("#697651"))
    order_v.add_child(order_title)
    _orders_box=HBoxContainer.new()
    _orders_box.add_theme_constant_override("separation",6)
    order_v.add_child(_orders_box)

    var recipe_panel:=_panel(_ui_root,Vector2(18,1088),Vector2(684,84),Color("#FFF8E6"))
    var recipe_v:=VBoxContainer.new()
    recipe_v.add_theme_constant_override("separation",4)
    recipe_panel.add_child(recipe_v)
    _recipe_label=Label.new()
    _recipe_label.text="TARİF: Bir sipariş seç."
    _recipe_label.add_theme_font_size_override("font_size",14)
    _recipe_label.add_theme_color_override("font_color",Color("#5A6D50"))
    recipe_v.add_child(_recipe_label)
    _quality_bar=ProgressBar.new()
    _quality_bar.min_value=0
    _quality_bar.max_value=100
    _quality_bar.value=100
    _quality_bar.show_percentage=true
    _quality_bar.custom_minimum_size=Vector2(0,18)
    recipe_v.add_child(_quality_bar)

    var inventory_panel:=_panel(_ui_root,Vector2(18,1180),Vector2(684,400),Color("#FFF8E8"))
    var inventory_v:=VBoxContainer.new()
    inventory_v.add_theme_constant_override("separation",5)
    inventory_panel.add_child(inventory_v)
    var shelf_title:=Label.new()
    shelf_title.text="MALZEME RAFI  •  ÜRÜNÜ SEÇ, + İLE 10 ADET STOK AL"
    shelf_title.add_theme_font_size_override("font_size",13)
    shelf_title.add_theme_color_override("font_color",Color("#687650"))
    inventory_v.add_child(shelf_title)
    _stock_grid=GridContainer.new()
    _stock_grid.columns=4
    _stock_grid.add_theme_constant_override("h_separation",3)
    _stock_grid.add_theme_constant_override("v_separation",3)
    inventory_v.add_child(_stock_grid)
    for i in range(INGREDIENTS.size()):
        var cell:=HBoxContainer.new()
        cell.add_theme_constant_override("separation",2)
        var product_button:=Button.new()
        product_button.text=INGREDIENTS[i]["name"].to_upper()+"  x40"
        product_button.custom_minimum_size=Vector2(120,42)
        product_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        product_button.add_theme_font_size_override("font_size",11)
        product_button.add_theme_stylebox_override("normal",_button_style(Color("#F1E9D7"),Color("#655E4A")))
        product_button.pressed.connect(_on_ingredient_pressed.bind(i))
        cell.add_child(product_button)
        var buy_button:=Button.new()
        buy_button.text="+"
        buy_button.custom_minimum_size=Vector2(30,42)
        buy_button.add_theme_font_size_override("font_size",18)
        buy_button.add_theme_stylebox_override("normal",_button_style(Color("#F7D88D"),Color("#805B2B")))
        buy_button.pressed.connect(_purchase_ingredient.bind(i))
        cell.add_child(buy_button)
        _stock_grid.add_child(cell)

    var actions:=HBoxContainer.new()
    actions.add_theme_constant_override("separation",8)
    inventory_v.add_child(actions)
    _mix_button=_make_action_button("KARIŞTIR",Color("#79B18D"))
    _mix_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _mix_button.pressed.connect(_mix_drink)
    actions.add_child(_mix_button)
    _serve_button=_make_action_button("MÜŞTERİYE VER",Color("#E98E78"))
    _serve_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    _serve_button.pressed.connect(_serve_drink)
    actions.add_child(_serve_button)

    _status_label=Label.new()
    _status_label.position=Vector2(35,1038)
    _status_label.size=Vector2(650,42)
    _status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    _status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
    _status_label.add_theme_font_size_override("font_size",14)
    _status_label.add_theme_color_override("font_color",Color("#FFF9E9"))
    _status_label.add_theme_color_override("font_shadow_color",Color("#5D574A"))
    _status_label.add_theme_constant_override("shadow_offset_x",1)
    _status_label.add_theme_constant_override("shadow_offset_y",2)
    _ui_root.add_child(_status_label)

    _closed_panel=_panel(_ui_root,Vector2(62,430),Vector2(596,300),Color("#FFF6E5"))
    _closed_panel.visible=false
    var closed_v:=VBoxContainer.new()
    _closed_v_align(closed_v)
    _closed_panel.add_child(closed_v)
    var closed_title:=Label.new()
    closed_title.text="KAFE KAPANDI"
    closed_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    closed_title.add_theme_font_size_override("font_size",30)
    closed_title.add_theme_color_override("font_color",Color("#B34B42"))
    closed_v.add_child(closed_title)
    var closed_text:=Label.new()
    closed_text.text="Müşteri memnuniyet puanın 2.00 yıldızın altına düştü."
    closed_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    closed_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    closed_text.add_theme_font_size_override("font_size",17)
    closed_text.add_theme_color_override("font_color",Color("#6D624F"))
    closed_v.add_child(closed_text)

func _closed_v_align(box: VBoxContainer) -> void:
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    box.alignment=BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation",18)

func _panel(parent: Control, pos: Vector2, dimensions: Vector2, color: Color) -> PanelContainer:
    var panel:=PanelContainer.new()
    panel.position=pos
    panel.size=dimensions
    var style:=StyleBoxFlat.new()
    style.bg_color=color
    style.corner_radius_top_left=20
    style.corner_radius_top_right=20
    style.corner_radius_bottom_left=20
    style.corner_radius_bottom_right=20
    style.border_width_bottom=2
    style.border_color=Color("#E8D6B7")
    style.content_margin_left=12
    style.content_margin_right=12
    style.content_margin_top=8
    style.content_margin_bottom=8
    panel.add_theme_stylebox_override("panel",style)
    parent.add_child(panel)
    return panel

func _button_style(background: Color, foreground: Color) -> StyleBoxFlat:
    var style:=StyleBoxFlat.new()
    style.bg_color=background
    style.corner_radius_top_left=10
    style.corner_radius_top_right=10
    style.corner_radius_bottom_left=10
    style.corner_radius_bottom_right=10
    style.content_margin_left=5
    style.content_margin_right=5
    style.content_margin_top=4
    style.content_margin_bottom=4
    style.border_width_bottom=2
    style.border_color=background.darkened(0.13)
    return style

func _make_action_button(text: String, background: Color) -> Button:
    var button:=Button.new()
    button.text=text
    button.custom_minimum_size=Vector2(0,45)
    button.add_theme_font_size_override("font_size",16)
    button.add_theme_color_override("font_color",Color("#FFFDF2"))
    button.add_theme_stylebox_override("normal",_button_style(background,Color.WHITE))
    button.add_theme_stylebox_override("hover",_button_style(background.lightened(0.08),Color.WHITE))
    button.add_theme_stylebox_override("pressed",_button_style(background.darkened(0.12),Color.WHITE))
    return button

func _refresh_hud() -> void:
    if _header_cash==null:
        return
    _header_cash.text="$"+_format_money(_cash)
    _header_rating.text="★ %.2f"%_rating
    _header_level.text="LVL %d"%_level
    _refresh_order_cards()
    _refresh_recipe()
    if _status_label!=null:
        _status_label.text=_message if _message_timer>0.0 else "Siparişleri zamanında hazırla; memnuniyetini yüksek tut."
    if _quality_bar!=null:
        _quality_bar.value=_quality
    if _mix_button!=null:
        _mix_button.disabled=_bar_closed or _current_customer().is_empty() or _mixed
    if _serve_button!=null:
        _serve_button.disabled=_bar_closed or _current_customer().is_empty() or not _mixed
    if _stock_grid!=null:
        for i in range(mini(INGREDIENTS.size(),_stock_grid.get_child_count())):
            var cell:HBoxContainer=_stock_grid.get_child(i)
            var product:Button=cell.get_child(0)
            product.text=INGREDIENTS[i]["name"].to_upper()+"  x"+str(_stock[i])
            product.disabled=_stock[i]<=0 or _current_customer().is_empty() or _mixed

func _refresh_order_cards() -> void:
    if _orders_box==null:
        return
    for child in _orders_box.get_children():
        child.queue_free()
    var visible:=0
    for c in _customers:
        if not _customer_has_order(c):
            continue
        var drink:Dictionary=DRINKS[int(c["drink"])]
        var button:=Button.new()
        button.custom_minimum_size=Vector2(158,70)
        button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        var mood:String="SİPARİŞ BEKLİYOR"
        if c["state"]=="angry":
            mood="SABIRSIZ"
        elif c["state"]=="banging":
            mood="MASAYA VURUYOR!"
        button.text="%s  •  $%d\n%s\n%s"%(c["name"],drink["price"],drink["short"],mood)
        button.add_theme_font_size_override("font_size",11)
        var background:Color=Color("#F4EBD7")
        if int(c["id"])==_selected_customer_id:
            background=Color("#F8DFA7")
        if c["state"]=="banging":
            background=Color("#F7D6C9")
        button.add_theme_stylebox_override("normal",_button_style(background,Color("#6B5F49")))
        button.pressed.connect(_select_order.bind(int(c["id"])))
        _orders_box.add_child(button)
        visible+=1
        if visible>=4:
            break
    if visible==0:
        var waiting:=Label.new()
        waiting.text="Yeni misafirler birazdan masalara gelecek."
        waiting.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
        waiting.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
        waiting.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        waiting.add_theme_font_size_override("font_size",13)
        waiting.add_theme_color_override("font_color",Color("#887D64"))
        _orders_box.add_child(waiting)

func _refresh_recipe() -> void:
    if _recipe_label==null:
        return
    var c:Dictionary=_current_customer()
    if c.is_empty():
        _recipe_label.text="TARİF: Sipariş kartından bir müşteri seç."
        return
    var drink:Dictionary=DRINKS[int(c["drink"])]
    var recipe:Array=drink["recipe"]
    var steps:PackedStringArray=[]
    for i in range(recipe.size()):
        var step_text:String=INGREDIENTS[int(recipe[i])]["name"]
        if i<_recipe_step:
            step_text="✓ "+step_text
        elif i==_recipe_step and not _mixed:
            step_text="▶ "+step_text
        steps.append(step_text)
    steps.append("KARIŞTIR")
    _recipe_label.text="%s  •  $%d  •  %s"%(drink["name"],drink["price"],"  →  ".join(steps))

func _format_money(value: int) -> String:
    var raw:=str(value)
    var out: String=""
    for i in range(raw.length()):
        if i>0 and (raw.length()-i)%3==0:
            out+=","
        out+=raw[i]
    return out

# MESH / MATERIAL HELPERS

func _mat(hex: String, roughness: float=0.78, metallic: float=0.0) -> StandardMaterial3D:
    if _materials.has(hex):
        return _materials[hex]
    var material:=StandardMaterial3D.new()
    material.albedo_color=Color(hex)
    material.roughness=roughness
    material.metallic=metallic
    _materials[hex]=material
    return material

func _add_mesh(parent: Node3D, node_name: String, mesh: Mesh, material: Material,
        position: Vector3, scale: Vector3=Vector3.ONE) -> MeshInstance3D:
    var instance:=MeshInstance3D.new()
    instance.name=node_name
    instance.mesh=mesh
    instance.material_override=material
    instance.position=position
    instance.scale=scale
    instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    parent.add_child(instance)
    return instance

func _make_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3,
        material: Material) -> MeshInstance3D:
    var mesh:=BoxMesh.new()
    mesh.size=size
    return _add_mesh(parent,node_name,mesh,material,position)

func _make_sphere(parent: Node3D, node_name: String, position: Vector3, radius: float,
        material: Material, scale: Vector3=Vector3.ONE) -> MeshInstance3D:
    var mesh:=SphereMesh.new()
    mesh.radius=radius
    mesh.height=radius*2.0
    mesh.radial_segments=20
    mesh.rings=12
    return _add_mesh(parent,node_name,mesh,material,position,scale)

func _make_capsule(parent: Node3D, node_name: String, position: Vector3, radius: float,
        height: float, material: Material) -> MeshInstance3D:
    var mesh:=CapsuleMesh.new()
    mesh.radius=radius
    mesh.height=height
    mesh.radial_segments=16
    mesh.rings=8
    return _add_mesh(parent,node_name,mesh,material,position)

func _make_cylinder(parent: Node3D, node_name: String, top_radius: float, bottom_radius: float,
        height: float, position: Vector3, material: Material,
        rotation: Vector3=Vector3.ZERO) -> MeshInstance3D:
    var mesh:=CylinderMesh.new()
    mesh.top_radius=top_radius
    mesh.bottom_radius=bottom_radius
    mesh.height=height
    mesh.radial_segments=20
    var instance:=_add_mesh(parent,node_name,mesh,material,position)
    instance.rotation=rotation
    return instance

func _make_label_in_world(position: Vector3, text: String, color: Color, size: float) -> void:
    var label:=Label3D.new()
    label.text=text
    label.position=position
    label.font_size=48
    label.pixel_size=0.01*size
    label.modulate=color
    label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test=true
    add_child(label)
