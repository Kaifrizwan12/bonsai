class CleanScreen {
  dynamic build(dynamic context) {
    return CustomAppBar(
      profileSection: ProfileSection(),
      settingsButton: SettingsButton(),
    );
  }
}

class CustomAppBar {
  CustomAppBar(
      {required ProfileSection profileSection,
      required SettingsButton settingsButton});
}

class ProfileSection {
  ProfileSection();
}

class SettingsButton {
  SettingsButton();
}
