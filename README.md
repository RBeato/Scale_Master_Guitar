# test

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## SoundFont Usage

This project uses a single SoundFont file, `FluidR3_GM.sf2`, for all instrument sounds (drums, keys, bass, etc.).

- All code references to `.sf2` files now use `assets/sounds/sf2/FluidR3_GM.sf2`.
- The file is **not included in the main repository** because it is larger than 100MB.
- `FluidR3_GM.sf2` is tracked with [Git LFS](https://git-lfs.github.com/). If you clone the repo, make sure you have Git LFS installed:

```sh
git lfs install
git lfs pull
```

If you do not see the file after cloning, download it manually and place it in `assets/sounds/sf2/`.

**Note:** If you add other large audio files, use Git LFS or exclude them from the main repo.
