import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:pixel_adventure/actors/player.dart';
import 'package:pixel_adventure/levels/level.dart';

class PixelAdventure extends FlameGame with HasKeyboardHandlerComponents {
  @override
  Color backgroundColor() => Color(0xff211f30);

  late final CameraComponent cameraComponent;

  Player player = Player();

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    final world = Level(player: player, levelName: 'Level-01');

    cameraComponent = CameraComponent.withFixedResolution(
      world: world,
      width: 640,
      height: 360,
    );
    cameraComponent.viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    return super.onLoad();
  }
}
