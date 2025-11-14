;=========================================
; Project: LC-3 Rocket & Meteor Game
; Author : Anusha Majumder
; Date   : 4th April, 2025
;=========================================
;Description:
;  This is a 2D ASCII-based game on a 20x6 grid. The rocket moves using
;  W (up), A (left), S (down), D (right) and avoids a moving meteor (*).
;  The game ends when the rocket:
;    - Quits manually using q (state = 1)
;    - Collides with a meteor (state = 2)
;    - Scores 9 points (wait till the * finishes another line of leftward) by dodging enough meteors (state = 3) 
;======================================
;Inputs     : Keyboard input (wasd, q)  - ONLY SMALL LETTERS
;Outputs    : ASCII screen display, game messages
;Processing : Grid rendering, rocket movement, meteor movement,
;             collision checking, score updating
;===================================
;Register Usage:
;R0 - General purpose / input character / loop counter
;R1 - Temporary storage and comparison
;R2 - Y position counter (row)
;R3 - X position counter (column)
;R7 - Subroutine return address
;================

.ORIG x3000

;==== START ====
; Initializes game state: clears screen, sets rocket/meteor positions,
; sets score and random seed
START    
    LD R0, CLEAR_C
    OUT
    
    AND R0, R0, #0
    ADD R0, R0, #5      ; Set rocket X = 5
    ST R0, ROCKET_X
    ADD R0, R0, #-3     ; Set rocket Y = 2
    ST R0, ROCKET_Y
    
    LD R0, CHAR_UP      ; Set rocket character = '^'
    ST R0, ROCKET_C
    
    AND R0, R0, #0
    ADD R0, R0, #9      ; Meteor X = 9
    ST R0, METEOR_X
    ADD R0, R0, #-7     ; Meteor Y = 2
    ST R0, METEOR_Y
    
    AND R0, R0, #0      ; Score = 0
    ST R0, SCORE
    ST R0, GAME_OVER
    
    ADD R0, R0, #7      ; Seed = 7
    ST R0, SEED

;==== LOOP ====
; Main game loop:
;   - Clears screen
;   - Draws grid
;   - Reads input
;   - Updates rocket position
;   - Moves meteor
;   - Checks for collision
;   - Ends if GAME_OVER state is set (1, 2, or 3)
LOOP
    LD R0, CLEAR_C
    OUT

    JSR DRAW_SCREEN
    GETC

    ; Check for Q = Quit
    LD R1, ASCII_Q
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRnp CHECK_W
    
    AND R0, R0, #0
    ADD R0, R0, #1      ; GAME_OVER = 1
    ST R0, GAME_OVER
    BR CHECK_GAME_END

; Each of the following checks handles rocket input
; Movement is only applied if inside grid boundaries

CHECK_W
    ; Move up
    LD R1, ASCII_W
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRnp CHECK_A

    LD R0, ROCKET_Y
    ADD R0, R0, #-1
    BRn SKIP_MOVE_UP
    ST R0, ROCKET_Y
SKIP_MOVE_UP
    LD R0, CHAR_UP
    ST R0, ROCKET_C
    BR VALID_INPUT

CHECK_A
    ; Move left
    LD R1, ASCII_A
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRnp CHECK_S

    LD R0, ROCKET_X
    ADD R0, R0, #-1
    BRn SKIP_MOVE_LEFT
    ST R0, ROCKET_X
SKIP_MOVE_LEFT
    LD R0, CHAR_LEFT
    ST R0, ROCKET_C
    BR VALID_INPUT

CHECK_S
    ; Move down
    LD R1, ASCII_S
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRnp CHECK_D

    LD R0, ROCKET_Y
    ADD R0, R0, #1
    LD R1, GRID_HEIGHT
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRz SKIP_MOVE_DOWN
    ST R0, ROCKET_Y
SKIP_MOVE_DOWN
    LD R0, CHAR_DOWN
    ST R0, ROCKET_C
    BR VALID_INPUT

CHECK_D
    ; Move right
    LD R1, ASCII_D
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRnp CHECK_GAME_END

    LD R0, ROCKET_X
    ADD R0, R0, #1
    LD R1, GRID_WIDTH
    ADD R1, R1, #-1
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRp SKIP_MOVE_RIGHT
    ST R0, ROCKET_X
SKIP_MOVE_RIGHT
    LD R0, CHAR_RIGHT
    ST R0, ROCKET_C

;==== VALID_INPUT ====
; Meteor updates and collision check only happen after valid key
VALID_INPUT
    JSR MOVE_METEOR
    JSR CHECK_COLLISION

CHECK_GAME_END
    LD R0, GAME_OVER
    BRp END_GAME
    BR LOOP

;==== END_GAME ====
; Handles final game state message
; GAME_OVER values:
;   1 = quit manually
;   2 = collision with meteor
;   3 = win by reaching score of 9
END_GAME
    LD R0, CLEAR_C
    OUT

    LD R0, GAME_OVER
    ADD R0, R0, #-1
    BRz SHOW_QUIT

    ADD R0, R0, #-1
    BRz SHOW_CRASH

    LEA R0, MSG_WIN
    PUTS
    HALT

SHOW_CRASH
    LEA R0, MSG_CRASH
    PUTS
    HALT

SHOW_QUIT
    LEA R0, MSG_EXIT
    PUTS
    HALT

;==== DRAW_SCREEN ====
; Draws the 20x6 grid with rocket and meteor characters
; Displays score and controls at bottom
DRAW_SCREEN
    ST R7, SAVE_R7

    LD R0, CLEAR_C
    OUT

    AND R2, R2, #0      ; Y = 0
DRAW_ROW
    AND R3, R3, #0      ; X = 0

DRAW_COL
    ; Check rocket position
    LD R0, ROCKET_X
    NOT R0, R0
    ADD R0, R0, #1
    ADD R0, R3, R0
    BRnp TRY_METEOR

    LD R0, ROCKET_Y
    NOT R0, R0
    ADD R0, R0, #1
    ADD R0, R2, R0
    BRnp TRY_METEOR

    LD R0, ROCKET_C
    OUT
    BR NEXT_COL

TRY_METEOR
    ; Check meteor position
    LD R0, METEOR_X
    NOT R0, R0
    ADD R0, R0, #1
    ADD R0, R3, R0
    BRnp DRAW_EMPTY

    LD R0, METEOR_Y
    NOT R0, R0
    ADD R0, R0, #1
    ADD R0, R2, R0
    BRnp DRAW_EMPTY

    LD R0, CHAR_METEOR
    OUT
    BR NEXT_COL

DRAW_EMPTY
    LD R0, CHAR_SPACE
    OUT

NEXT_COL
    ADD R3, R3, #1
    LD R0, GRID_WIDTH
    NOT R0, R0
    ADD R0, R0, #1
    ADD R0, R3, R0
    BRnp DRAW_COL

    LD R0, CHAR_NL
    OUT
    ADD R2, R2, #1
    LD R0, GRID_HEIGHT
    NOT R0, R0
    ADD R0, R0, #1
    ADD R0, R2, R0
    BRnp DRAW_ROW

    LEA R0, MSG_SCORE
    PUTS
    LD R0, SCORE
    LD R1, ASCII_0
    ADD R0, R0, R1
    OUT

    LD R0, CHAR_NL
    OUT
    LEA R0, MSG_CONTROLS
    PUTS

    LD R7, SAVE_R7
    RET

;==== MOVE_METEOR ====
; Moves the meteor left, resets if off-screen, and increases score
; If score reaches 9, sets GAME_OVER = 3 (win)
MOVE_METEOR
    ST R7, SAVE_R7

    LD R0, METEOR_X
    ADD R0, R0, #-1
    BRp SAVE_METEOR

    LD R0, SCORE
    ADD R0, R0, #1
    ADD R1, R0, #-9
    BRp CAP_SCORE
    ST R0, SCORE
    BR RESET_METEOR

CAP_SCORE
    AND R0, R0, #0
    ADD R0, R0, #9
    ST R0, SCORE
    AND R0, R0, #0
    ADD R0, R0, #3
    ST R0, GAME_OVER
    BR METEOR_DONE

RESET_METEOR
    AND R0, R0, #0
    ADD R0, R0, #9
    ST R0, METEOR_X

    LD R0, SEED
    ADD R0, R0, R0
    ADD R0, R0, #5
    ST R0, SEED

RANDOM_MOD
    LD R1, GRID_HEIGHT
    ADD R1, R1, #1
    NOT R1, R1
    ADD R1, R1, #1
    ADD R0, R0, R1
    BRzp RANDOM_MOD

    LD R1, GRID_HEIGHT
    ADD R1, R1, #1
    ADD R0, R0, R1
    ST R0, METEOR_Y
    BR METEOR_DONE

SAVE_METEOR
    ST R0, METEOR_X

METEOR_DONE
    LD R7, SAVE_R7
    RET

;==== CHECK_COLLISION ====
; Ends game if rocket and meteor share same X and Y position
; Sets GAME_OVER = 2 if collision detected
CHECK_COLLISION
    ST R7, SAVE_R7

    LD R0, ROCKET_X
    LD R1, METEOR_X
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRnp NO_COLLISION

    LD R0, ROCKET_Y
    LD R1, METEOR_Y
    NOT R1, R1
    ADD R1, R1, #1
    ADD R1, R0, R1
    BRnp NO_COLLISION

    AND R0, R0, #0
    ADD R0, R0, #2
    ST R0, GAME_OVER

NO_COLLISION
    LD R7, SAVE_R7
    RET
;==================================
; Game Variables (modifiable)
;==================================
ROCKET_X    .FILL #0      ; Current X position of the rocket (0 to 9)
ROCKET_Y    .FILL #0      ; Current Y position of the rocket (0 to 5)
ROCKET_C    .FILL #0      ; ASCII character representing rocket's current direction

METEOR_X    .FILL #0      ; Current X position of the meteor
METEOR_Y    .FILL #0      ; Current Y position of the meteor

SCORE       .FILL #0      ; Current rocket score (0 to 9)
GAME_OVER   .FILL #0      ; Game state:
                         ; 0 = ongoing
                         ; 1 = rocket quit
                         ; 2 = collision
                         ; 3 = win

SEED        .FILL #0      ; Seed value for generating pseudo-random meteor Y position
SAVE_R7     .FILL #0      ; Used to save/restore R7 in subroutines

;==================================
; Game Constants
;==================================
GRID_WIDTH   .FILL #20     ; Width of the grid (should be 10, seems like typo)
GRID_HEIGHT  .FILL #6      ; Height of the grid (0 to 5)

;==================================
; ASCII Character Constants
;==================================
CHAR_UP     .FILL x5E      ; '^' - Rocket facing up
CHAR_DOWN   .FILL x76      ; 'v' - Rocket facing down
CHAR_LEFT   .FILL x3C      ; '<' - Rocket facing left
CHAR_RIGHT  .FILL x3E      ; '>' - Rocket facing right

CHAR_METEOR .FILL x2A      ; '*' - Meteor symbol
CHAR_SPACE  .FILL x2E      ; '.' - Empty space on grid
CHAR_NL     .FILL x0A      ; Newline character (line break)
CLEAR_C     .FILL x0C      ; Form feed character (clears screen in LC3 simulator)

;==================================
; ASCII Values for Key Inputs
;==================================
ASCII_W     .FILL x77      ; 'w' key for up
ASCII_A     .FILL x61      ; 'a' key for left
ASCII_S     .FILL x73      ; 's' key for down
ASCII_D     .FILL x64      ; 'd' key for right
ASCII_Q     .FILL x71      ; 'q' key to quit
ASCII_0     .FILL x30      ; '0' character, used for score display

;==================================
; Game Messages
;==================================
MSG_EXIT     .STRINGZ "Thanks for playing!\n"         ; Message shown if rocket quits
MSG_CRASH    .STRINGZ "GAME OVER! Ship crashed!\n"    ; Message on meteor collision
MSG_WIN      .STRINGZ "WELL DONE! YOU WON!\n"         ; Message when score reaches 9
MSG_CONTROLS .STRINGZ "WASD: Move  Q: Quit\n"         ; Control instructions
MSG_SCORE    .STRINGZ "Score: "                       ; Prefix before displaying score

.END         ; End of program

