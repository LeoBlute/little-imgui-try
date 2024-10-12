package main

import rl "vendor:raylib"
import "core:fmt"
import "core:strings"
import "core:crypto/hash"

ui_id :: distinct [16]byte

ui_panel :: struct {
   opened: bool,
   active: bool,
   position: [2]i32,
   size:     [2]i32,
   identifier: ui_id
}

panels : [dynamic]ui_panel
active_panel : Maybe(ui_id)

ui_begin :: proc(name: string, #any_int x, y: i32, #any_int extra_unique_identifier: int = 0, loc:= #caller_location) -> bool {
   assert(active_panel == nil)

   id_string_builder := strings.builder_make(context.temp_allocator)
   id_string := fmt.sbprintf(&id_string_builder, loc.file_path, loc.procedure, loc.line, loc.column, extra_unique_identifier)

   bytes := hash.hash_string(.SHA3_256, id_string, context.temp_allocator)
   generated_id : ui_id

   for &b, i in generated_id {
      b = bytes[i]
   }

   for &panel in panels {
      if panel.identifier != generated_id {
         continue
      }
      assert(panel.active == false)

      panel.active = true
      active_panel = panel.identifier
      return true
   }

   new_panel : ui_panel = {
      opened = true,
      active = true,
      position = {x, y},
      size = {100, 100}
   }

   new_panel.identifier = generated_id

   append(&panels, new_panel);
   active_panel = new_panel.identifier

   return true
}

ui_end :: proc() {
   assert(active_panel != nil)

   active_panel = nil
}

ui_held_panel :: struct {
   mouse_position: [2]i32,
   position: [2]i32,
   id: ui_id
}

main :: proc() {
   rl.SetTraceLogLevel(.WARNING)
   rl.InitWindow(1280, 720, "")
   rl.SetTargetFPS(144)

   held_panel : Maybe(ui_held_panel) = nil

   for !rl.WindowShouldClose() {
      free_all(context.temp_allocator)
      rl.BeginDrawing()
      rl.ClearBackground(rl.BLACK)
      defer rl.EndDrawing()

      ui_begin("", 80, 50)
      ui_end()

      ui_begin("", 80, 180)
      ui_end()

      mouse_position :[2]i32= {auto_cast rl.GetMouseX(), auto_cast rl.GetMouseY()}

      assert(active_panel == nil)
      for &panel in panels {
         panel.active = false

         hp, ok := held_panel.?
         if ok && hp.id == panel.identifier {
            panel.position = hp.position + (mouse_position - hp.mouse_position)
            if !rl.IsMouseButtonDown(.LEFT) && hp.id == panel.identifier {
               held_panel = nil
            }
         } else if rl.IsMouseButtonPressed(.LEFT) && rl.CheckCollisionPointRec({auto_cast mouse_position.x, auto_cast mouse_position.y}, {auto_cast panel.position.x, auto_cast panel.position.y, auto_cast panel.size.x, auto_cast panel.size.y}) {
            held_panel = ui_held_panel {
               mouse_position = mouse_position,
               position = panel.position,
               id = panel.identifier
            }
         }

         color := rl.WHITE
         if ok && hp.id == panel.identifier {
            color = rl.RED
         }
         rl.DrawRectangle(panel.position.x, panel.position.y, panel.size.x, panel.size.y, color)
      }
   }
}