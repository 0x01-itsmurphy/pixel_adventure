import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

import 'player.dart';

enum ChickenState { idle, hit, run }

class Chicken extends SpriteAnimationGroupComponent
    with HasGameReference<PixelAdventure> {
  final double offNeg;
  final double offPos;
  Chicken({super.position, super.size, this.offNeg = 0.0, this.offPos = 0.0});

  late final Player player;
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation runAnimation;

  static const double stepTime = 0.05;
  Vector2 textureSize = Vector2(32, 34);

  static const int tileSize = 16;
  double rangeNeg = 0;
  double rangePos = 0;
  double moveDirection = 1;
  double targetDirection = -1;

  Vector2 velocity = Vector2.zero();
  static const int runSpeed = 80;

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    player = game.player;
    _loadAllAnimations();
    _calculateRange();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    _updateState();
    _movement(dt);
    super.update(dt);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 13);
    runAnimation = _spriteAnimation('Run', 14);
    hitAnimation = _spriteAnimation('Hit', 5)..loop = false;

    animations = {
      ChickenState.idle: idleAnimation,
      ChickenState.hit: hitAnimation,
      ChickenState.run: runAnimation,
    };

    current = ChickenState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Chicken/$state (32x34).png'),
      SpriteAnimationData.sequenced(
        amount: amount,
        stepTime: stepTime,
        textureSize: textureSize,
      ),
    );
  }

  void _calculateRange() {
    rangeNeg = position.x - offNeg * tileSize;
    rangePos = position.x + offPos * tileSize;
  }

  void _movement(double dt) {
    velocity.x = 0;
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double chickenrOffset = (scale.x > 0) ? 0 : -width;
    if (playerInRange()) {
      //
      targetDirection = (player.x + playerOffset < position.x + chickenrOffset)
          ? -1
          : 1;
      velocity.x = targetDirection * runSpeed;
    }
    moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;
    position.x += velocity.x * dt;
  }

  bool playerInRange() {
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;

    return player.x + playerOffset >= rangeNeg &&
        player.x + playerOffset <= rangePos &&
        player.y + player.height > position.y &&
        player.y < position.y + height;
  }

  void _updateState() {
    current = (velocity.x != 0) ? ChickenState.run : ChickenState.idle;
    if ((moveDirection > 0 && scale.x > 0) ||
        (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }
}
