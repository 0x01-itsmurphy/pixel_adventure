import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:pixel_adventure/components/checkpoint.dart';
import 'package:pixel_adventure/components/collision_block.dart';
import 'package:pixel_adventure/components/custom_hitbox.dart';
import 'package:pixel_adventure/components/fruit.dart';
import 'package:pixel_adventure/components/saw.dart';
import 'package:pixel_adventure/components/utils.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

enum PlayerState {
  idle,
  running,
  falling,
  jumping,
  hit,
  appearing,
  disappearing,
}

class Player extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure>, KeyboardHandler, CollisionCallbacks {
  final String character;

  Player({super.position, this.character = 'Ninja Frog'});

  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disAppearingAnimation;

  Vector2 startingPosition = Vector2.zero();

  final double stepTime = 0.05;

  double _gravity = 9.6;
  double _jumpForce = 260;
  double _terminalVelocity = 300;

  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 velocity = Vector2.zero();
  bool isFacingRight = true;

  bool isOnGround = false;
  bool hasJumped = false;

  bool gotHit = false;
  bool reachedCheckpoint = false;

  List<CollisionBlock> collisionsBlock = [];

  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10,
    offsetY: 4,
    width: 14,
    height: 28,
  );

  double fixedDeltaTime = 1 / 60; // 60 FPS
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimation();
    startingPosition = Vector2(position.x, position.y);
    add(
      RectangleHitbox(
        position: Vector2(hitbox.offsetX, hitbox.offsetY),
        size: Vector2(hitbox.width, hitbox.height),
      ),
    );
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;

    while (accumulatedTime >= fixedDeltaTime) {
      if (!gotHit && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisions();
        _applyGravity(fixedDeltaTime);
        _checkVerticleCollisions();
      }
      accumulatedTime -= fixedDeltaTime;
    }
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Fruit) other.coollidedWithPlayer();
      if (other is Saw) _reSpawn();
      if (other is Checkpoint && !reachedCheckpoint) _reachedCheckpoint();
    }

    super.onCollision(intersectionPoints, other);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft);

    final isRightKeyPressed =
        keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight);

    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);

    return super.onKeyEvent(event, keysPressed);
  }

  void _loadAllAnimation() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    fallingAnimation = _spriteAnimation('Fall', 1);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    hitAnimation = _spriteAnimation('Hit', 7);
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disAppearingAnimation = _specialSpriteAnimation('Desappearing', 7);

    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disAppearingAnimation,
    };

    current = PlayerState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache("Main Characters/$character/$state (32x32).png"),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(32),
      ),
    );
  }

  SpriteAnimation _specialSpriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache("Main Characters/$state (96x96).png"),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: Vector2.all(96),
      ),
    );
  }

  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0) {
      flipHorizontallyAroundCenter();
    }

    if (velocity.x > 0 || velocity.x < 0) {
      playerState = PlayerState.running;
    }

    if (velocity.y > 0) playerState = PlayerState.falling;
    if (velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }

  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJumped(dt);

    velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJumped(double dt) {
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }

  void _checkHorizontalCollisions() {
    for (var block in collisionsBlock) {
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }

  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }

  void _checkVerticleCollisions() {
    for (var block in collisionsBlock) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.width - hitbox.offsetY;
          }
        }
      }
    }
  }

  void _reSpawn() {
    final hitDuration = Duration(milliseconds: 350);
    final appearingDuration = Duration(milliseconds: 350);
    final canMoveDuration = Duration(milliseconds: 400);

    gotHit = true;
    current = PlayerState.hit;
    Future.delayed(hitDuration, () {
      scale.x = 1;
      position = startingPosition - Vector2.all(32); // 96 - 64 = 32
      current = PlayerState.appearing;
      Future.delayed(appearingDuration, () {
        velocity = Vector2.zero();
        position = startingPosition;
        _updatePlayerState();
        Future.delayed(canMoveDuration, () => gotHit = false);
      });
    });
  }

  void _reachedCheckpoint() {
    reachedCheckpoint = true;

    if (scale.x > 0) {
      position = position - Vector2.all(32);
    } else if (scale.x < 0) {
      position = position + Vector2(32, -32);
    }

    final reachedCheckpointDuration = Duration(milliseconds: 50 * 7);
    Future.delayed(reachedCheckpointDuration, () {
      reachedCheckpoint = false;
      position = Vector2.all(-640);

      final waitToChangeDuration = Duration(seconds: 3);
      Future.delayed(waitToChangeDuration, () {
        game.loadNextLevel();
      });
    });

    current = PlayerState.disappearing;
  }
}
