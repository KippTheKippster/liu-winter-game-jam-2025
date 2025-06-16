extends Node2D

enum Action {
	IDLE,
	SLEEPING,
}

enum Direction {
	LEFT = -1,
	RIGHT = 1,
}

@export var direction: Direction = Direction.RIGHT
@export var action: Action
