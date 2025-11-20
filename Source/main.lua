import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer" 

local gfx = playdate.graphics

-- Screen size
local SCREEN_WIDTH  = 400
local SCREEN_HEIGHT = 240

-- Paddle settings
local PADDLE_WIDTH  = 8
local PADDLE_HEIGHT = 40
local PADDLE_SPEED  = 4

-- Ball settings
local BALL_SIZE     = 6
local BALL_SPEED    = 3

-- Game objects
local leftPaddle = {
    x = 20,
    y = SCREEN_HEIGHT/2 - PADDLE_HEIGHT/2
}

local rightPaddle = {
    x = SCREEN_WIDTH - 20 - PADDLE_WIDTH,
    y = SCREEN_HEIGHT/2 - PADDLE_HEIGHT/2
}

local ball = {
    x  = SCREEN_WIDTH/2 - BALL_SIZE/2,
    y  = SCREEN_HEIGHT/2 - BALL_SIZE/2,
    vx = BALL_SPEED,
    vy = BALL_SPEED
}

local leftScore  = 0
local rightScore = 0

--------------------------------------------------
-- Helper: reset ball after a point
--------------------------------------------------
local function resetBall(direction)
    ball.x = SCREEN_WIDTH/2 - BALL_SIZE/2
    ball.y = SCREEN_HEIGHT/2 - BALL_SIZE/2

    -- direction: 1 = right, -1 = left
    ball.vx = BALL_SPEED * direction
    -- random-ish vertical speed
    ball.vy = BALL_SPEED * (math.random() > 0.5 and 1 or -1)
end

--------------------------------------------------
-- Playdate callbacks
--------------------------------------------------

function playdate.update()
    -- 1. Input
    -- Left paddle: up/down buttons
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        leftPaddle.y -= PADDLE_SPEED
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        leftPaddle.y += PADDLE_SPEED
    end

    -- Right paddle: crank!
    local crankPos = playdate.getCrankPosition()  -- 0-359
    -- Map crank angle to screen height
    rightPaddle.y = (crankPos / 360) * (SCREEN_HEIGHT - PADDLE_HEIGHT)

    -- Clamp paddles inside screen
    if leftPaddle.y < 0 then leftPaddle.y = 0 end
    if leftPaddle.y > SCREEN_HEIGHT - PADDLE_HEIGHT then
        leftPaddle.y = SCREEN_HEIGHT - PADDLE_HEIGHT
    end

    if rightPaddle.y < 0 then rightPaddle.y = 0 end
    if rightPaddle.y > SCREEN_HEIGHT - PADDLE_HEIGHT then
        rightPaddle.y = SCREEN_HEIGHT - PADDLE_HEIGHT
    end

    -- 2. Move ball
    ball.x += ball.vx
    ball.y += ball.vy

    -- 3. Collisions with top/bottom
    if ball.y <= 0 then
        ball.y = 0
        ball.vy = -ball.vy
    elseif ball.y + BALL_SIZE >= SCREEN_HEIGHT then
        ball.y = SCREEN_HEIGHT - BALL_SIZE
        ball.vy = -ball.vy
    end

    -- 4. Collisions with paddles
    -- Left paddle
    if ball.x <= leftPaddle.x + PADDLE_WIDTH
        and ball.x + BALL_SIZE >= leftPaddle.x
        and ball.y + BALL_SIZE >= leftPaddle.y
        and ball.y <= leftPaddle.y + PADDLE_HEIGHT then

        ball.x  = leftPaddle.x + PADDLE_WIDTH
        ball.vx = -ball.vx
    end

    -- Right paddle
    if ball.x + BALL_SIZE >= rightPaddle.x
        and ball.x <= rightPaddle.x + PADDLE_WIDTH
        and ball.y + BALL_SIZE >= rightPaddle.y
        and ball.y <= rightPaddle.y + PADDLE_HEIGHT then

        ball.x  = rightPaddle.x - BALL_SIZE
        ball.vx = -ball.vx
    end

    -- 5. Scoring: if ball goes off left/right
    if ball.x + BALL_SIZE < 0 then
        rightScore += 1
        resetBall(1) -- send ball to the right
    elseif ball.x > SCREEN_WIDTH then
        leftScore += 1
        resetBall(-1) -- send ball to the left
    end

    -- 6. Draw everything
    gfx.clear(gfx.kColorBlack)

    -- Middle line
    gfx.setColor(gfx.kColorWhite)
    for y = 0, SCREEN_HEIGHT, 8 do
        gfx.drawLine(SCREEN_WIDTH/2, y, SCREEN_WIDTH/2, y + 4)
    end

    -- Paddles
    gfx.fillRect(leftPaddle.x,  leftPaddle.y,  PADDLE_WIDTH, PADDLE_HEIGHT)
    gfx.fillRect(rightPaddle.x, rightPaddle.y, PADDLE_WIDTH, PADDLE_HEIGHT)

    -- Ball
    gfx.fillRect(ball.x, ball.y, BALL_SIZE, BALL_SIZE)

    -- Score
    gfx.setFont(gfx.getSystemFont())
    gfx.drawTextAligned(tostring(leftScore),  SCREEN_WIDTH/2 - 30, 10, kTextAlignment.center)
    gfx.drawTextAligned(tostring(rightScore), SCREEN_WIDTH/2 + 30, 10, kTextAlignment.center)

    -- Required at end of update
    playdate.timer.updateTimers()
end

function playdate.cranked(change, acceleratedChange)
    -- We're using crank position directly in update(),
    -- but you could also do crank-based movement here if you want.
end
