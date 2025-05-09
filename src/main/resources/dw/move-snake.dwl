%dw 2.0
output application/json

var body = payload.you.body
var board = payload.board
var head = body[0] // First body part is always head
var neck = body[1] // Second body part is always neck
var others = payload.board.snakes map ((sanke, snakeID) ->[sanke.body map ((item, index) -> [item.x, item.y])])

var moves ={"up":[0,1],
    "down":[0,-1],
    "left":[-1,0],
    "right":[1,0]}

// Step 0: Find my neck location so I don't eat myself

// TODO: Step 1 - Don't hit walls.
// Use information from `board` and `head` to not move beyond the game board.


// TODO: Step 2 - Don't hit yourself.
// Use information from `body` to avoid moves that would collide with yourself.
var nextBodyLocation = body map ((item, index) ->
    [item.x, item.y])
    filter ((item, index) -> index != sizeOf(body)-1)
var nextHeadLocation = moves mapObject
    ((value, key,index) ->(key):
        (value) map ((item, i) ->(item)+ head[i])
    ) filterObject ((value, key, index) ->
            (value[0]>=0)and
            (value[0]<=board.width)and
            (value[1]>=0)and
            (value[1])<=board.height
        )
var bodyMoves = keysOf(
        nextHeadLocation filterObject ((value, key, index) ->
            others contains ((value))
        )
    ) map ((item, index) -> item as String)



// TODO: Step 3 - Don't collide with others.
// Use information from `payload` to prevent your Battlesnake from colliding with others.

var otherCollision = keysOf(
        nextHeadLocation filterObject ((value, key, index) ->
            nextBodyLocation contains ((value))
        )
    ) map ((item, index) -> item as String)

// TODO: Step 4 - Find food.
// Use information in `payload` to seek out and find food.
// food = board.food


// Find safe moves by eliminating neck location and any other locations computed in above steps
var safeMoves = keysOf(nextHeadLocation)
    map ((item, index) -> (item) as String)
    filter ((item, index) ->
        !(
            (bodyMoves contains(item) )or
            (otherCollision contains(item))
        )
    )

// Next random move from safe moves
var nextMove = safeMoves[randomInt(sizeOf(safeMoves))]

---
{
	move: nextMove,
	shout: "Moving $(nextMove)"
}
