import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:pixel_adventure/pixel_adventure.dart';

class JumpButton extends SpriteComponent
    with HasGameReference<PixelAdventure>, TapCallbacks {
  JumpButton();

  double margin = 32;
  double buttonSize = 64;

  @override
  FutureOr<void> onLoad() async {
    sprite = Sprite(game.images.fromCache('HUD/JumpButton.png'));

    size = Vector2.all(buttonSize);

    position = Vector2(640 - margin - buttonSize, 360 - margin - buttonSize);
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player.hasJumped = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player.hasJumped = false;
    super.onTapUp(event);
  }
}
