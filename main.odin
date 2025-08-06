package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

OFFSET :: 20
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
PIPE_WIDTH :: 100
PIPE_SPACE :: 200
PIPE_COUNT :: 5
GAP_HEIGHT :: 120
HORIZONTAL_SPEED :: 50
BALL_RADIUS :: 10

ball_pos := rl.Vector2{200, 300}
ball_velocity := rl.Vector2{0, 0}
gravity: f32 = 500.0
jump: f32 : -250.0
dt: f32

Pipe :: struct {
	x:      f32,
	gap_y:  f32,
	scored: bool,
}
pipes: [PIPE_COUNT]Pipe

game_over := false
started := false
score := 0

// Finds the maximum x of all pipes (rightmost one)
max_elem :: proc(arr: [PIPE_COUNT]Pipe) -> f32 {
	max := arr[0].x
	for pipe in arr {
		if pipe.x > max {
			max = pipe.x
		}
	}
	return max
}

restart :: proc() {
	//started = false
	score = 0
	game_over = false
	ball_pos = rl.Vector2{200, 300}
	ball_velocity = rl.Vector2{0, 0}
	for i in 0 ..< PIPE_COUNT {
		pipes[i] = Pipe {
			x      = f32(SCREEN_WIDTH + i * (PIPE_WIDTH + PIPE_SPACE)),
			gap_y  = OFFSET + (SCREEN_HEIGHT - GAP_HEIGHT - OFFSET * 2) * rand.float32(),
			scored = false,
		}
	}
}

main :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "FlappyBird")
	rl.SetTargetFPS(60)

	for i in 0 ..< PIPE_COUNT {
		pipes[i] = Pipe {
			x      = f32(SCREEN_WIDTH + i * (PIPE_WIDTH + PIPE_SPACE)),
			gap_y  = OFFSET + (SCREEN_HEIGHT - GAP_HEIGHT - OFFSET * 2) * rand.float32(),
			scored = false,
		}
	}

	for !rl.WindowShouldClose() {
		//update
		if !started && !game_over {
			if rl.IsKeyPressed(.SPACE) {
				started = true
			}
		} else if game_over {
			if rl.IsKeyPressed(.SPACE) {
				restart()
				ball_velocity.y = jump
			}
		} else {
			dt = rl.GetFrameTime()

			if rl.IsKeyPressed(.SPACE) {
				ball_velocity.y = jump
			}

			ball_velocity.y += gravity * dt
			ball_pos.y += ball_velocity.y * dt

			// Clamp ball position to screen
			if ball_pos.y < 10 {
				ball_pos.y = 10
				ball_velocity.y = 0
			}
			if ball_pos.y > SCREEN_HEIGHT - 10 {
				ball_pos.y = SCREEN_HEIGHT - 10
				ball_velocity.y = 0
			}

			// Move and recycle pipes
			for i in 0 ..< PIPE_COUNT {
				pipes[i].x -= 2

				if !pipes[i].scored && pipes[i].x + PIPE_WIDTH < ball_pos.x {
					score += 1
					pipes[i].scored = true
				}

				if pipes[i].x + PIPE_WIDTH < 0 {
					pipes[i].x = max_elem(pipes) + f32(PIPE_WIDTH + PIPE_SPACE)
					pipes[i].gap_y =
						OFFSET + (SCREEN_HEIGHT - GAP_HEIGHT - OFFSET * 2) * rand.float32()
					pipes[i].scored = false
				}
			}

			// Collision detection
			for i in 0 ..< PIPE_COUNT {
				top_rec := rl.Rectangle{pipes[i].x, 0, PIPE_WIDTH, pipes[i].gap_y}
				bottom_rec := rl.Rectangle {
					pipes[i].x,
					pipes[i].gap_y + GAP_HEIGHT,
					PIPE_WIDTH,
					SCREEN_HEIGHT,
				}

				if rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, top_rec) ||
				   rl.CheckCollisionCircleRec(ball_pos, BALL_RADIUS, bottom_rec) {
					game_over = true
				}
			}

			if ball_pos.y + BALL_RADIUS > SCREEN_HEIGHT || ball_pos.y - BALL_RADIUS < 0 {
				game_over = true
			}
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.SKYBLUE)

		rl.DrawCircleV(ball_pos, BALL_RADIUS, rl.YELLOW)

		for i in 0 ..< PIPE_COUNT {
			// Top pipe
			rl.DrawRectangleV({pipes[i].x, 0}, {PIPE_WIDTH, pipes[i].gap_y}, {0, 200, 0, 255})
			// Bottom pipe
			rl.DrawRectangleV(
				{pipes[i].x, pipes[i].gap_y + GAP_HEIGHT},
				{PIPE_WIDTH, SCREEN_HEIGHT - (pipes[i].gap_y + GAP_HEIGHT)},
				{0, 200, 0, 255},
			)
		}

		if !game_over {
			score_text := fmt.ctprint(score)
			rl.DrawText(score_text, 5, 5, 15, rl.WHITE)
		}
		if !started {
			msg := fmt.ctprint("Press Space to Start")
			msg_wdt := rl.MeasureText(msg, 20)
			rl.DrawText(msg, SCREEN_WIDTH / 2 - msg_wdt / 2, SCREEN_HEIGHT / 2 - 10, 20, rl.WHITE)
		}

		if game_over {
			msg := fmt.ctprintf(" Score: %d \nPress Space to Restart", score)
			msg_wdt := rl.MeasureText(msg, 20)
			rl.DrawText(msg, SCREEN_WIDTH / 2 - msg_wdt / 2, SCREEN_HEIGHT / 2 - 10, 20, rl.WHITE)
		}

		rl.EndDrawing()
		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}
