#import "Basic";
#import "Math";

Random :: #import "Random";
Input :: #import "Input";
Simp :: #import "Simp";
Window :: #import "Window_Creation";

WINDOW_WIDTH  : s32 = 1280; 
WINDOW_HEIGHT : s32 = 720;

COLORS :: Vector4.[
    .{0.8, 0.1, 0.1, 0.9},
    .{0.1, 0.8, 0.1, 0.9},
    .{0.1, 0.3, 0.8, 0.9},
    .{0.8, 0.2, 0.8, 0.9},
];

State :: struct {
    window_width, window_height: s32;
    tetronimos: [..] Tetromino;
}

Tetromino :: struct {
    fill_map: [8] u8;
    color: Vector4;
    orientation: int;
    position: Vector2;
}

Tetromino_Type :: enum {
    I;
    J;
    L;
    O;
    S;
    T;
    Z;
}

make_tetromino :: (
    type: Tetromino_Type,
    color: Vector4,
    position: Vector2
) -> Tetromino {
    t: Tetromino = ---;
    t.color = color;
    t.orientation = 0;
    t.position = position;
    if #complete type == {
      case .I;
        t.fill_map = u8.[1, 1, 1, 1, 0, 0, 0, 0];
      case .J;
        t.fill_map = u8.[1, 1, 1, 0, 1, 0, 0, 0];
      case .L;
        t.fill_map = u8.[1, 1, 1, 0, 0, 0, 1, 0];
      case .O;
        t.fill_map = u8.[1, 1, 0, 0, 1, 1, 0, 0];
      case .S;
        t.fill_map = u8.[1, 1, 0, 0, 0, 1, 1, 0];
      case .T;
        t.fill_map = u8.[1, 1, 1, 0, 0, 1, 0, 0];
      case .Z;
        t.fill_map = u8.[0, 1, 1, 0, 1, 1, 0, 0];
    }
    return t;
}

random_tetromino_type :: () -> Tetromino_Type {
    types := enum_values_as_enum(Tetromino_Type);
    return types[Random.random_get() % xx types.count];
}

random_color :: () -> Vector4 {
    return COLORS[Random.random_get() % xx COLORS.count];
}

make_random_tetromino :: () -> Tetromino {
    return make_tetromino(random_tetromino_type(), random_color(), .{.5, 1});
}

render_tetromino :: (state: State, using t: Tetromino) {
    BLOCK_SIZE :: 50;

    pos_x := position.x * state.window_width;
    pos_y := position.y * state.window_height;

    for filled, i: fill_map {
        if !filled {
            continue;
        }
        
        second_row_step := ifx i > 3 then BLOCK_SIZE else 0;
        first_row_step := (i % 4) * BLOCK_SIZE;

        o := orientation;
        y_off := ifx o == 0 || o == 2 then second_row_step else first_row_step;
        x_off := ifx o == 1 || o == 3 then second_row_step else first_row_step;

        y := ifx o == 0 || o == 3 pos_y + y_off else pos_y - y_off;
        x := ifx o < 2 pos_x + x_off else pos_x - x_off;

        Simp.immediate_quad(x, y, x + BLOCK_SIZE, y + BLOCK_SIZE, color);
    }
}

rotate_tetromino :: (using t: *Tetromino) {
    orientation = (orientation + 1) % 4;
}

main :: () {
    state: State;
    state.window_width, state.window_height = WINDOW_WIDTH, WINDOW_HEIGHT;
    window := Window.create_window(
        window_name="Tetris",
        width=state.window_width,
        height=state.window_height
    );

    Simp.set_render_target(window);
    Simp.set_shader_for_color();

    t := make_random_tetromino();

    last_time, current_time: float;
    TICK_TIMEOUT :: 0.5;
    FALL_STEP :: 0.1;
    timeout := TICK_TIMEOUT;

    quit := false;
    while !quit {
        reset_temporary_storage();

        last_time, current_time = current_time, xx get_time();
        dt := current_time - last_time;

        Input.update_window_events();
        for Input.events_this_frame {
            if it.type == .QUIT quit = true;

            if it.type == .KEYBOARD && it.key_pressed {
                if it.key_code == {
                  case .ESCAPE;
                    quit = true;
                }
            }

            if it.type == .TEXT_INPUT {
                if it.utf32 == {
                  case #char "r";
                    rotate_tetromino(*t);
                }
            }
        }

        for Input.get_window_resizes() {
            Simp.update_window(it.window);

            if it.window == window {
                state.window_width, state.window_height = it.width, it.height;
            }
        }

        Simp.clear_render_target(.2, .3, .3, 1);

        timeout -= dt;
        if timeout < 0 {
            timeout = TICK_TIMEOUT;
            t.position.y -= FALL_STEP;
        }

        render_tetromino(state, t);

        Simp.swap_buffers(window);
    }
}
