import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:pixel_adventure/levels/level.dart';

class PixelAdventure extends FlameGame {
  @override
  Color backgroundColor() => Color(0xff211f30);

  late final CameraComponent cameraComponent;

  final world = Level(levelName: 'Level-01');

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

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
