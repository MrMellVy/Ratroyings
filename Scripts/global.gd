extends Node

var gameStarted: bool

var playerBody: CharacterBody2D
var playerDamageAmount: int
var playerDamageZone: Area2D
var playerAlive: bool
var playerHitbox: Area2D

var EnemyDamageZone: Area2D
var EnemyDamageAmount: int
var EnemyAirDamageZone: Area2D
var EnemyAirDamageAmount: int


var current_wave: int = 1
var moving_to_next_wave: bool
var saved_wave: int = 0
var is_continuing: bool = false
var saved_player_health: int = 100
var saved_player_damage_bonus: int = 0
var enemies_passive: bool = false

var high_score = 0
var current_score: int
var previous_score: int
var show_credits: bool = false
