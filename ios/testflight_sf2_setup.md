# TestFlight SF2 Sound Files Fix

This document provides instructions for fixing the SF2 sound files that aren't playing properly in TestFlight builds.

## Steps to Complete the Fix

### 1. Add the Run Script to Xcode Build Phases

1. Open your Flutter project's iOS folder in Xcode:
   ```
   open ios/Runner.xcworkspace
   ```

2. In Xcode, select the **Runner** project in the project navigator (left sidebar)

3. Select the **Build Phases** tab

4. Click the **+** button in the top-left of the Build Phases section and select **New Run Script Phase**

5. Drag the new Run Script phase to be just before the "Copy Bundle Resources" phase

6. Expand the newly created Run Script section

7. In the script field, enter:
   ```bash
   "$SRCROOT/sf2_copy.sh"
   ```

8. Name this run script "Copy SF2 Files" by double-clicking on the default "Run Script" name

### 2. Ensure SF2 Files are in Copy Bundle Resources

1. While still in the **Build Phases** tab, expand the **Copy Bundle Resources** section

2. Check if your SF2 files are listed there. If not:
   
   a. Click the **+** button
   
   b. Navigate to `assets/sounds/sf2/FluidR3_GM.sf2` and any other SF2 files
   
   c. Select the files and click **Add**

### 3. Clean and Build the Project

1. In Terminal, run:
   ```
   flutter clean
   flutter pub get
   flutter build ios --release
   ```

2. Archive and submit to TestFlight as usual

## What This Fix Does

1. The Podfile changes enable testability and proper resource bundling for TestFlight builds

2. The custom script ensures SF2 files are copied directly to the app bundle in a location accessible by the app in TestFlight

3. Removing duplicate UIBackgroundModes entries in Info.plist prevents conflicts

These changes should resolve the issue with SF2 files not playing in TestFlight builds while continuing to work in debug mode and direct installations.
