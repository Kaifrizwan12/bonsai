class DeepContextScreen {
  dynamic build(dynamic context) {
    return Level1(
      child: Level2(
        child: Level3(
          child: Level4(
            child: Level5(
              child: Level6(
                child: Level7(
                  child: Level8(
                    child: context.watch('theme'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Level1 {
  Level1({required dynamic child});
}

class Level2 {
  Level2({required dynamic child});
}

class Level3 {
  Level3({required dynamic child});
}

class Level4 {
  Level4({required dynamic child});
}

class Level5 {
  Level5({required dynamic child});
}

class Level6 {
  Level6({required dynamic child});
}

class Level7 {
  Level7({required dynamic child});
}

class Level8 {
  Level8({required dynamic child});
}
