%dw 2.0
import * from dw::core::Arrays
output application/json

var body = payload.you.body
var board = payload.board
var head = body[0] // First body part is always head
var neck = body[1] // Second body part is always neck
/*array that contains the body of other snakes, discard the tail since it will move:
    [
        [
            [s1[0].x,[s1[0].xy],
            ...,
            [s1[n-1].x,[s1[n-1].xy]
        ],
        ...,
        [snake n data]
    ]*/
var others = flatten(payload.board.snakes
	filter (
		(item, index) -> item.id != payload.you.id
	)
	map ((sanke, snakeID) ->
        [sanke.body map ((item, index) -> [item.x, item.y])
            take(sizeOf(sanke.body)-1)
        ]
        
    )
)
//array that contains the coordinates of all foods in the board
var foods = payload.board.food 
    map ((item, index) ->[item.x, item.y] )

var moves ={"up":[0,1],
    "down":[0,-1],
    "left":[-1,0],
    "right":[1,0]}

/*function that returns the closest item to the objective
    where group is: 
    [
        [x0,y0],
        ...
        [xn,yn]
    ]
    and objective is:
    [x,y]
*/
fun closestTo(group, objective) =
    group minBy ((item) ->
        sqrt(((item[0]-objective[0])pow 2 )
        + ((item[1]-objective[1])pow 2))
    )
    

/*function that returns the next possible head locations where 
    head is:[x,y]

    output:
    [
        [x0,y1],
        [x0,y2],
        [x1,y0],
        [x2,y0]
    ]

*/
fun nextHead(head) =
    valuesOf(moves) map ((item, index) -> [head[0] + item[0], head[1] + item[1]])


/*calculate the next body location, since the body follows the head,
the coordinates of each part of the body are the coordinates of the next*/
var nextBodyLocation = body map ((item, index) ->
    [item.x, item.y])
    take(sizeOf(body)-1)

/*create a map with each possible move and where the head will be placed if taken
    {"up":[x0,y1],"down":[x0,y2],"left":[x1,y0],"right":[x2,y0]}*/
var nextHeadLocation = moves mapObject
    ((value, key,index) ->(key):
        (value) map ((item, i) ->(item)+ head[i])
    ) filterObject ((value, key, index) ->
            (0 to board.width contains(value[0]))and
            (0 to board.height contains(value[1]))
        )
/*array that contains the moves that will collide with the body, ex:
    ["up","down"]*/  
var bodyMoves = keysOf(
        nextHeadLocation filterObject ((value, key, index) ->
            nextBodyLocation contains ((value))
        )
    ) map ((item, index) -> item as String)

/*array that contains the moves that will collide with the body of any other snake, ex:
    ["up","down"]*/  
var otherCollision = keysOf(
        nextHeadLocation filterObject ((value, key, index) ->
            flatten(others) contains ((value))
        )
    ) map ((item, index) -> item as String)

//array of moves that could collide with the head of a snake in the next turn
//ex: ["up","down"]
var possibleCollisions = others map (
    (item, index) ->
    keysOf(nextHeadLocation 
        filterObject ((value, key, index) -> 
            nextHead(item[0]) contains  (value)
        )
    )
    map((item, index) -> item as String)
)

/*sort possible collisions in :
    {
        "true": [up,down],
        "false": [left,right]
    }
    where true means that the my snake is bigger than the other snake
*/
var sortedCollisions = possibleCollisions groupBy ((item, index) -> sizeOf(body)>sizeOf(others[index]))

//array of moves that could collide with the head of a bigger snakein the next turn
var unsafeHeadCollisions = flatten(valuesOf(sortedCollisions
    filterObject((value, key, index) -> key as String == "false")
)map ((item, index) -> flatten(item)))


//Group the possible moves by their safety
var sortedMoves =  keysOf(nextHeadLocation)
    map ((item, index) -> (item) as String)
    filter ((item, index) ->
        !(
            (bodyMoves contains(item) )or
            (otherCollision contains(item))
        )
    )
    groupBy ((item, index) -> !(unsafeHeadCollisions contains(item)))


var safeMoves = sortedMoves["true"]
var unsafeMoves = sortedMoves["false"]


//list of possible moves that can kill a snake that are safe
var killMoves = flatten(valuesOf(sortedCollisions
        filterObject((value, key, index) -> key as String == "true")
    )map ((item, index) -> flatten(item)))
    filter ((item, index) -> safeMoves contains(item))


/*Calculate the closest move to the food, if multiple moves are available,
choose the first in the array*/
var closestFood = closestTo(foods,[head.x,head.y])

var closestMove = closestTo(safeMoves map ((item, index) ->
    nextHeadLocation[item]), closestFood)

var foodMove = keysOf(
        nextHeadLocation 
            filterObject ((value, key,index)->
            value == closestMove )
    )[0]

//calculate next move
var nextMove = 
    if (!isEmpty(killMoves)) killMoves[randomInt(sizeOf(killMoves))]
    else if (foodMove != null) foodMove
    else if (safeMoves == null) unsafeMoves[randomInt(sizeOf(unsafeMoves))]
    else safeMoves[randomInt(sizeOf(safeMoves))]

---
{
	move: nextMove,
	shout: "Moving $(nextMove)",
    "debug": sortedCollisions
}