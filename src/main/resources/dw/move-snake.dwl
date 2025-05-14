%dw 2.0
import * from dw::core::Arrays
output application/json

var body = payload.you.body
var board = payload.board
var head = body[0] // First body part is always head
var neck = body[1] // Second body part is always neck
var others = flatten(payload.board.snakes
	filter (
		(item, index) -> item.id != payload.you.id
	)
	map ((sanke, snakeID) ->[sanke.body map ((item, index) -> [item.x, item.y])])
)
var foods = payload.board.food 
    map ((item, index) ->[item.x, item.y] )

var moves ={"up":[0,1],
    "down":[0,-1],
    "left":[-1,0],
    "right":[1,0]}

fun closestTo(group, objective) =
    group minBy ((item) ->
        sqrt(((item[0]-objective[0])pow 2 )
        + ((item[1]-objective[1])pow 2))
    )
    
fun nextHead(head) =
    valuesOf(moves) map ((item, index) -> [head[0] + item[0], head[1] + item[1]])


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
            (0 to board.width contains(value[0]))and
            (0 to board.height contains(value[1]))
        )
var bodyMoves = keysOf(
        nextHeadLocation filterObject ((value, key, index) ->
            nextBodyLocation contains ((value))
        )
    ) map ((item, index) -> item as String)



// TODO: Step 3 - Don't collide with others.
// Use information from `payload` to prevent your Battlesnake from colliding with others.

var otherCollision = keysOf(
        nextHeadLocation filterObject ((value, key, index) ->
            flatten(others) contains ((value))
        )
    ) map ((item, index) -> item as String)


var possibleCollisions = others map (
    (item, index) ->
    keysOf(nextHeadLocation 
        filterObject ((value, key, index) -> 
            nextHead(item[0]) contains  (value)
        )
    )
    map((item, index) -> item as String)
)

var sortedCollisions = possibleCollisions groupBy ((item, index) -> sizeOf(body)>sizeOf(others[index]))

var unsafeHeadCollisions = flatten(valuesOf(sortedCollisions
    filterObject((value, key, index) -> key as String == "false")
)map ((item, index) -> flatten(item)))

var killMoves = flatten(valuesOf(sortedCollisions
    filterObject((value, key, index) -> key as String == "true")
)map ((item, index) -> flatten(item)))




// TODO : Step 4 - Find food.
// Use information in `payload` to seek out and find food.
// food = board.food
var closestFood = closestTo(foods,[head.x,head.y])



// Find safe moves by eliminating neck location and any other locations computed in above steps

var safeMoves = keysOf(nextHeadLocation)
    map ((item, index) -> (item) as String)
    filter ((item, index) ->
        !(
            (bodyMoves contains(item) )or
            (otherCollision contains(item))or
            (unsafeHeadCollisions contains(item))
        )
    )

// Next random move from safe moves


var closestMove = closestTo(safeMoves map ((item, index) ->
    nextHeadLocation[item]), closestFood)

var foodMove = keysOf(
        nextHeadLocation 
            filterObject ((value, key,index)->
            value == closestMove )
    )[0]

var nextMove = 
    if (!isEmpty(killMoves)) killMoves[randomInt(sizeOf(killMoves))]
    else if (foodMove != null) foodMove
    else safeMoves[randomInt(sizeOf(safeMoves))]

---
{
	move: nextMove,
	shout: "Moving $(nextMove)"
}