import sys
import random

def build_level(name, size, file_name, num_enemies=4, num_pillars=0, num_torches=0, num_chests=1, add_interact_altar=False):
    lines = []
    lines.append(f'; KayKit Dungeon Remastered — {name}')
    lines.append('')
    lines.append(f'[gd_scene format=3 uid="uid://{name.lower()}_001"]')
    lines.append('')
    lines.append('; === External Resources ===')
    lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/floor_tile_small.gltf" id="1_floortile"]')
    lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/wall.gltf" id="2_wall"]')
    lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/wall_corner.gltf" id="3_wallcorner"]')
    lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/chest_gold.gltf" id="4_chest"]')
    lines.append('[ext_resource type="Script" path="res://Scripts/altar_interact.gd" id="5_altarinteract"]')
    lines.append('[ext_resource type="PackedScene" path="res://Scene/skeleton_enemy.tscn" id="6_skeleton"]')
    lines.append('[ext_resource type="PackedScene" path="res://Scene/player.tscn" id="7_player"]')
    lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/wall_pillar.gltf" id="8_pillar"]')
    lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/torch_mounted.gltf" id="9_torch"]')
    lines.append('')
    lines.append('; === Sub-resources ===')
    if add_interact_altar:
        lines.append('[sub_resource type="SphereShape3D" id="SphereShape3D_interact"]')
        lines.append('radius = 2.0')
        lines.append('')
    
    center = (size - 1) / 2.0
    floor_size = size
    lines.append('[sub_resource type="BoxShape3D" id="BoxShape3D_floor"]')
    lines.append(f'size = Vector3({floor_size}, 0.2, {floor_size})')
    lines.append('')
    lines.append('[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]')
    lines.append('size = Vector3(0.8, 0.8, 0.8)')
    lines.append('')
    lines.append('[sub_resource type="BoxShape3D" id="BoxShape3D_pillar"]')
    lines.append('size = Vector3(0.8, 4.0, 0.8)')
    lines.append('')

    lines.append('; === SCENE TREE ===')
    lines.append('')
    lines.append(f'[node name="{name}" type="Node3D"]')
    lines.append('')
    lines.append('[node name="FloorCollision" type="StaticBody3D" parent="."]')
    lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {center},-0.1,{center})')
    lines.append('')
    lines.append('[node name="FloorShape" type="CollisionShape3D" parent="FloorCollision"]')
    lines.append('shape = SubResource("BoxShape3D_floor")')
    lines.append('')
    lines.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]')
    lines.append('')
    lines.append('[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]')
    lines.append('transform = Transform3D(0.866025, -0.433013, 0.25, 0, 0.5, 0.866025, -0.5, -0.75, 0.433013, 0, 8, 0)')
    lines.append('light_energy = 1.2')
    lines.append('shadow_enabled = true')
    lines.append('')

    lines.append('[node name="OmniLight3D" type="OmniLight3D" parent="."]')
    lines.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {center}, 2.5, {center})')
    lines.append('light_color = Color(1.0, 0.85, 0.6, 1)')
    lines.append('light_energy = 4.0')
    lines.append(f'omni_range = {size + 4}.0')
    lines.append('')

    lines.append(f'; --- Floor tiles: {size}x{size} grid ---')
    lines.append('[node name="Floor" type="Node3D" parent="."]')
    lines.append('')
    for z in range(size):
        for x in range(size):
            lines.append(f'[node name="Tile_{x}_{z}" parent="Floor" instance=ExtResource("1_floortile")]')
            lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {x},0,{z})')
    lines.append('')

    last_pos = size - 0.5
    lines.append('; --- Walls ---')
    lines.append('[node name="Walls" type="Node3D" parent="."]')
    lines.append('')
    lines.append('; South Wall')
    for x in range(size):
        lines.append(f'[node name="Wall_S_{x}" parent="Walls" instance=ExtResource("2_wall")]')
        lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {x},0,-0.5)')
    lines.append('')
    lines.append('; North Wall')
    for x in range(size):
        lines.append(f'[node name="Wall_N_{x}" parent="Walls" instance=ExtResource("2_wall")]')
        lines.append(f'transform = Transform3D(-1,0,0, 0,1,0, 0,0,-1, {x},0,{last_pos})')
    lines.append('')
    lines.append('; West Wall')
    for z in range(size):
        lines.append(f'[node name="Wall_W_{z}" parent="Walls" instance=ExtResource("2_wall")]')
        lines.append(f'transform = Transform3D(0,0,1, 0,1,0, -1,0,0, -0.5,0,{z})')
    lines.append('')
    lines.append('; East Wall')
    for z in range(size):
        lines.append(f'[node name="Wall_E_{z}" parent="Walls" instance=ExtResource("2_wall")]')
        lines.append(f'transform = Transform3D(0,0,-1, 0,1,0, 1,0,0, {last_pos},0,{z})')
    lines.append('')
    lines.append('; Corners')
    lines.append('[node name="Corner_SW" parent="Walls" instance=ExtResource("3_wallcorner")]')
    lines.append('transform = Transform3D(1,0,0, 0,1,0, 0,0,1, -0.5,0,-0.5)')
    lines.append('[node name="Corner_SE" parent="Walls" instance=ExtResource("3_wallcorner")]')
    lines.append(f'transform = Transform3D(0,0,-1, 0,1,0, 1,0,0, {last_pos},0,-0.5)')
    lines.append('[node name="Corner_NE" parent="Walls" instance=ExtResource("3_wallcorner")]')
    lines.append(f'transform = Transform3D(-1,0,0, 0,1,0, 0,0,-1, {last_pos},0,{last_pos})')
    lines.append('[node name="Corner_NW" parent="Walls" instance=ExtResource("3_wallcorner")]')
    lines.append(f'transform = Transform3D(0,0,1, 0,1,0, -1,0,0, -0.5,0,{last_pos})')
    lines.append('')

    lines.append('; --- Pillars ---')
    lines.append('[node name="Pillars" type="Node3D" parent="."]')
    lines.append('')
    for i in range(num_pillars):
        px = random.randint(2, size-3)
        pz = random.randint(2, size-3)
        lines.append(f'[node name="Pillar_{i}" parent="Pillars" instance=ExtResource("8_pillar")]')
        lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {px},0,{pz})')
        lines.append(f'[node name="StaticBody3D" type="StaticBody3D" parent="Pillars/Pillar_{i}"]')
        lines.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Pillars/Pillar_{i}/StaticBody3D"]')
        lines.append('shape = SubResource("BoxShape3D_pillar")')
        lines.append('transform = Transform3D(1,0,0, 0,1,0, 0,0,1, 0,2,0)')
        lines.append('')

    lines.append('; --- Props ---')
    lines.append('[node name="Props" type="Node3D" parent="."]')
    lines.append('')
    for i in range(num_chests):
        px = random.randint(3, size-4)
        pz = random.randint(3, size-4)
        if add_interact_altar and i == 0:
            px, pz = center, center
        
        lines.append(f'[node name="Chest_{i}" type="StaticBody3D" parent="Props"]')
        lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {px},0,{pz})')
        lines.append(f'[node name="Mesh" parent="Props/Chest_{i}" instance=ExtResource("4_chest")]')
        lines.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Props/Chest_{i}"]')
        lines.append('shape = SubResource("BoxShape3D_chest")')
        if add_interact_altar and i == 0:
            lines.append(f'[node name="InteractionZone" type="Area3D" parent="Props/Chest_{i}"]')
            lines.append('script = ExtResource("5_altarinteract")')
            lines.append(f'[node name="InteractShape" type="CollisionShape3D" parent="Props/Chest_{i}/InteractionZone"]')
            lines.append('shape = SubResource("SphereShape3D_interact")')
        lines.append('')
        
    lines.append('; --- Skeleton Enemies ---')
    lines.append('[node name="Enemies" type="Node3D" parent="."]')
    lines.append('')
    for i in range(num_enemies):
        sx = random.randint(2, size-3)
        sz = random.randint(2, size-3)
        lines.append(f'[node name="Skeleton_{i+1}" parent="Enemies" instance=ExtResource("6_skeleton")]')
        lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {sx},0,{sz})')
        lines.append('')

    # Player as instanced scene
    lines.append('; --- Player (instanced from player.tscn) ---')
    lines.append('[node name="Player" parent="." instance=ExtResource("7_player")]')
    lines.append('transform = Transform3D(1,0,0, 0,1,0, 0,0,1, 2,1,2)')

    content = '\n'.join(lines)
    with open(f'Scene/{file_name}', 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Generated {file_name} with size {size}x{size}, {num_enemies} enemies.')

# Level 1: 16x16, 4 enemies, central interactable chest
build_level("MainLevel", size=16, file_name="MainLevel.tscn", num_enemies=4, num_pillars=0, num_torches=0, num_chests=1, add_interact_altar=True)

# Level 2: 32x32, 15 enemies, 12 pillars, many chests (just props)
build_level("Level2", size=32, file_name="Level2.tscn", num_enemies=15, num_pillars=12, num_torches=0, num_chests=5, add_interact_altar=False)
