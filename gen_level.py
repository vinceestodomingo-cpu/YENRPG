import sys

SIZE = 16  # 16x16 floor grid

lines = []
lines.append('; KayKit Dungeon Remastered — MainLevel (expanded 16x16, Knight player, medieval UI)')
lines.append('; Player spawns at (2, 1, 2). Skeleton enemies patrol the room.')
lines.append('')
lines.append('[gd_scene format=3 uid="uid://main_level_001"]')
lines.append('')
lines.append('; === External Resources ===')
lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/floor_tile_small.gltf" id="1_floortile"]')
lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/wall.gltf" id="2_wall"]')
lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/wall_corner.gltf" id="3_wallcorner"]')
lines.append('[ext_resource type="PackedScene" path="res://Assets/gltf/chest_gold.gltf" id="4_chest"]')
lines.append('[ext_resource type="Script" path="res://Scripts/altar_interact.gd" id="5_altarinteract"]')
lines.append('[ext_resource type="PackedScene" path="res://Scene/skeleton_enemy.tscn" id="6_skeleton"]')
lines.append('[ext_resource type="PackedScene" path="res://Scene/player.tscn" id="7_player"]')
lines.append('')
lines.append('; === Sub-resources ===')
lines.append('[sub_resource type="SphereShape3D" id="SphereShape3D_interact"]')
lines.append('radius = 2.0')
lines.append('')

center = (SIZE - 1) / 2.0
floor_size = SIZE
lines.append('[sub_resource type="BoxShape3D" id="BoxShape3D_floor"]')
lines.append(f'size = Vector3({floor_size}, 0.2, {floor_size})')
lines.append('')
lines.append('[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]')
lines.append('size = Vector3(0.8, 0.8, 0.8)')
lines.append('')

lines.append('; === SCENE TREE ===')
lines.append('')
lines.append('[node name="MainLevel" type="Node3D"]')
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
lines.append(f'omni_range = {SIZE + 4}.0')
lines.append('')
lights = [(3,3,'NW'),(13,3,'NE'),(13,13,'SE'),(3,13,'SW')]
for (lx,lz,ln) in lights:
    lines.append(f'[node name="OmniLight_{ln}" type="OmniLight3D" parent="."]')
    lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {lx},2.0,{lz})')
    lines.append('light_color = Color(0.9, 0.7, 1.0, 1)')
    lines.append('light_energy = 2.0')
    lines.append('omni_range = 8.0')
    lines.append('')

lines.append(f'; --- Floor tiles: {SIZE}x{SIZE} grid ---')
lines.append('[node name="Floor" type="Node3D" parent="."]')
lines.append('')
for z in range(SIZE):
    for x in range(SIZE):
        lines.append(f'[node name="Tile_{x}_{z}" parent="Floor" instance=ExtResource("1_floortile")]')
        lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {x},0,{z})')
lines.append('')

last_pos = SIZE - 0.5
lines.append('; --- Walls ---')
lines.append('[node name="Walls" type="Node3D" parent="."]')
lines.append('')
lines.append('; South Wall')
for x in range(SIZE):
    lines.append(f'[node name="Wall_S_{x}" parent="Walls" instance=ExtResource("2_wall")]')
    lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {x},0,-0.5)')
lines.append('')
lines.append('; North Wall')
for x in range(SIZE):
    lines.append(f'[node name="Wall_N_{x}" parent="Walls" instance=ExtResource("2_wall")]')
    lines.append(f'transform = Transform3D(-1,0,0, 0,1,0, 0,0,-1, {x},0,{last_pos})')
lines.append('')
lines.append('; West Wall')
for z in range(SIZE):
    lines.append(f'[node name="Wall_W_{z}" parent="Walls" instance=ExtResource("2_wall")]')
    lines.append(f'transform = Transform3D(0,0,1, 0,1,0, -1,0,0, -0.5,0,{z})')
lines.append('')
lines.append('; East Wall')
for z in range(SIZE):
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

lines.append(f'; --- Center Prop: KayKit Chest ---')
lines.append(f'[node name="CentralAltar" type="StaticBody3D" parent="."]')
lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {center},0,{center})')
lines.append('')
lines.append('[node name="ChestMesh" parent="CentralAltar" instance=ExtResource("4_chest")]')
lines.append('')
lines.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="CentralAltar"]')
lines.append('shape = SubResource("BoxShape3D_chest")')
lines.append('')
lines.append('[node name="InteractionZone" type="Area3D" parent="CentralAltar"]')
lines.append('script = ExtResource("5_altarinteract")')
lines.append('')
lines.append('[node name="InteractShape" type="CollisionShape3D" parent="CentralAltar/InteractionZone"]')
lines.append('shape = SubResource("SphereShape3D_interact")')
lines.append('')

skel_positions = [(3.5, 3.5),(12.5, 3.5),(3.5, 12.5),(12.5, 12.5)]
lines.append('; --- Skeleton Enemies ---')
lines.append('[node name="Enemies" type="Node3D" parent="."]')
lines.append('')
for i, (sx, sz) in enumerate(skel_positions):
    lines.append(f'[node name="Skeleton_{i+1}" parent="Enemies" instance=ExtResource("6_skeleton")]')
    lines.append(f'transform = Transform3D(1,0,0, 0,1,0, 0,0,1, {sx},0,{sz})')
    lines.append('')

# Player as instanced scene
lines.append('; --- Player (instanced from player.tscn) ---')
lines.append('[node name="Player" parent="." instance=ExtResource("7_player")]')
lines.append('transform = Transform3D(1,0,0, 0,1,0, 0,0,1, 2,1,2)')

content = '\n'.join(lines)
with open('Scene/MainLevel.tscn', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done! Lines:', len(lines))
