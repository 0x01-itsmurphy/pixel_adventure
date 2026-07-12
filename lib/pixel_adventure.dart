import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import 'package:pixel_adventure/components/jump_button.dart';
import 'package:pixel_adventure/components/level.dart';
import 'package:pixel_adventure/components/player.dart';

class PixelAdventure extends FlameGame
    with
        HasKeyboardHandlerComponents,
        DragCallbacks,
        HasCollisionDetection,
        TapCallbacks {
  @override
  Color backgroundColor() => Color(0xff211f30);

  late CameraComponent cameraComponent;
  Player player = Player(character: 'Mask Dude');
  late JoystickComponent joystick;
  bool joystickReady = false;

  bool showControls = true;

  List<String> levelsName = ['Level-01', 'Level-01'];
  int currentLevelIndex = 0;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    _loadLevel();

    return super.onLoad();
  }

  void _loadLevel() {
    Future.delayed(const Duration(seconds: 1), () {
      final world = Level(
        player: player,
        levelName: levelsName[currentLevelIndex],
      );

      cameraComponent = CameraComponent.withFixedResolution(
        world: world,
        width: 640,
        height: 360,
      );
      cameraComponent.viewfinder.anchor = Anchor.topLeft;

      addAll([cameraComponent, world]);

      if (showControls) {
        addJoystick();
      }
    });
  }

  void loadNextLevel() {
    removeWhere((component) => component is Level);

    if (currentLevelIndex < levelsName.length - 1) {
      currentLevelIndex++;
      _loadLevel();
    } else {
      //
    }
  }

  @override
  void update(double dt) {
    if (showControls && joystickReady) {
      updateJoystick();
    }
    super.update(dt);
  }

  void addJoystick() {
    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(sprite: Sprite(images.fromCache('HUD/Knob.png'))),
      background: SpriteComponent(
        sprite: Sprite(images.fromCache('HUD/Joystick.png')),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    joystickReady = true;

    cameraComponent.viewport.addAll([joystick, JumpButton()]);
  }

  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }
}
