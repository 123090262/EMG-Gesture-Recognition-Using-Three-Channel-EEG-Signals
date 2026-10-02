# Three-Channel sEMG Repository Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the existing BME3201 folder into a public, hardware-deployment-focused research repository and publish it to the configured GitHub `main` branch without changing the implemented recognition algorithm.

**Architecture:** Preserve the two ESP32-S3 transports, MATLAB training/App workflow, browser client, saved model, raw recordings, and project media as separate, clearly named repository units. Keep the MATLAB App, feature function, and saved model together, make the training script resolve the external data directory from its own path, and use documentation to state protocol and scientific limitations precisely.

**Tech Stack:** ESP32 Arduino, C++, MATLAB R2024b App Designer, Statistics and Machine Learning Toolbox, Signal Processing Toolbox, HTML/CSS/JavaScript, WebSocket, Git, Git LFS, Markdown

## Global Constraints

- Do not change filters, feature definitions, labels, classifier settings, or the saved model.
- Preserve the existing remote `main` history and use a normal push, never a force push.
- Publish all requested artifacts while removing only the byte-identical duplicate presentation.
- Apply the MIT License only to original source code; use `DATA_LICENSE.md` for all non-code artifacts.
- Report 95.1% only as the course-presentation result from a window-level random holdout with an overlap-leakage warning.
- Treat the system as a research and teaching prototype, not a medical device.

---

### Task 1: Repository Layout and Binary Tracking

**Files:**
- Create: `.gitattributes`
- Create: `.gitignore`
- Move: `serial_tx_bin(1)/serial_tx_bin/serial_tx_bin.ino` to `firmware/serial/serial_tx_bin.ino`
- Move: `wifi_emg/wifi_emg.ino` to `firmware/wifi/wifi_emg.ino`
- Move: `EMG_recognition.mlapp` to `matlab/EMG_recognition.mlapp`
- Move: `Train_EMG_Model.m` to `matlab/Train_EMG_Model.m`
- Move: `getEMGFeatures.m` to `matlab/getEMGFeatures.m`
- Move: `MyTrainedModel.mat` to `matlab/MyTrainedModel.mat`
- Move: `MyEMGData/*.mat` to `data/raw/*.mat`
- Move: `emg/index.html` to `web/index.html`
- Move: `EMG.pptx` to `docs/presentation/EMG.pptx`
- Move: `MATLAB展示.mp4` to `docs/media/matlab-desktop-demo.mp4`
- Move: `手机APP展示.mp4` to `docs/media/web-mobile-demo.mp4`
- Remove: `emg/EMG.pptx` after verifying its SHA-256 matches `EMG.pptx`
- Remove: `serial_tx_bin(1)/serial_tx_bin/.theia/settings.json`

**Interfaces:**
- Consumes: the current untracked project tree and the existing `origin/main` history.
- Produces: the approved repository tree with binary artifacts tracked by Git LFS.

- [ ] **Step 1: Verify all move and delete sources resolve inside the workspace**

Run a PowerShell table of `Resolve-Path` results for every source and compare the two PPTX SHA-256 hashes.

- [ ] **Step 2: Create repository metadata**

Create `.gitattributes` with Git LFS rules for `*.mat`, `*.mlapp`, `*.mp4`, and `*.pptx`, plus text normalization for source and documentation. Create `.gitignore` for MATLAB autosaves, generated code, Simulink cache, OS files, IDE files, and temporary exports.

- [ ] **Step 3: Move each artifact to its approved destination**

Create exact destination directories and use literal paths. Move files individually, then delete only empty legacy directories and the verified duplicate PPTX.

- [ ] **Step 4: Verify the resulting inventory and LFS routing**

Run `rg --files`, `git lfs track`, and `git check-attr filter --` against representative MAT, MLAPP, MP4, and PPTX files. Confirm there is one PPTX and 66 MAT files.

- [ ] **Step 5: Commit the repository layout**

```powershell
git add .gitattributes .gitignore firmware matlab web data docs/presentation docs/media
git diff --cached --check
git commit -m "chore: organize EMG research project"
```

### Task 2: Relocatable MATLAB Training Paths

**Files:**
- Modify: `matlab/Train_EMG_Model.m`

**Interfaces:**
- Consumes: `data/raw/*.mat`, `matlab/getEMGFeatures.m`, and the existing training configuration.
- Produces: `matlab/MyTrainedModel.mat` through paths resolved from `mfilename('fullpath')`.

- [ ] **Step 1: Add a static regression check for legacy working-directory paths**

Run a PowerShell assertion that fails while the script contains `dataRootDir = 'MyEMGData'` or saves the model through an unqualified filename.

- [ ] **Step 2: Confirm the regression check fails before the edit**

Expected result: a nonzero exit code identifying the legacy relative path.

- [ ] **Step 3: Apply the minimal path-only implementation**

Define `scriptDir = fileparts(mfilename('fullpath'));`, set `dataRootDir = fullfile(scriptDir, '..', 'data', 'raw');`, set `modelOutputPath = fullfile(scriptDir, 'MyTrainedModel.mat');`, and pass `modelOutputPath` to `save`. Do not alter signal processing, features, partitioning, classifier configuration, plots, or labels.

- [ ] **Step 4: Re-run static checks and inspect the diff**

Confirm the old data directory literal and unqualified save call are absent, the new paths are present, and `git diff --check` reports no whitespace errors.

- [ ] **Step 5: Commit the path fix**

```powershell
git add matlab/Train_EMG_Model.m
git commit -m "fix: make MATLAB training paths relocatable"
```

### Task 3: Hardware and Application Images

**Files:**
- Create: `docs/images/hardware-controller.png`
- Create: `docs/images/hardware-electrode-setup.png`
- Create: `docs/images/matlab-app.png`

**Interfaces:**
- Consumes: embedded images in `docs/presentation/EMG.pptx` and the MLAPP screenshot in `matlab/EMG_recognition.mlapp`.
- Produces: repository-local images referenced by README.

- [ ] **Step 1: Map presentation relationships to the two slide-7 hardware images**

Verify slide 7 references `ppt/media/image11.png` and `ppt/media/image12.png` and inspect both before use.

- [ ] **Step 2: Extract the approved image assets without altering them**

Copy the two PPTX media entries to the hardware image paths and the MLAPP `metadata/appScreenshot.png` entry to `docs/images/matlab-app.png`.

- [ ] **Step 3: Inspect all three images**

Open each output at high detail. Confirm the photos show the ESP32-S3/sensor wiring and forearm electrode setup, and confirm the App screenshot is legible.

- [ ] **Step 4: Commit the documentation images**

```powershell
git add docs/images
git commit -m "docs: add hardware and application images"
```

### Task 4: Licensing and Hardware-Focused README

**Files:**
- Modify: `README.md`
- Create: `LICENSE`
- Create: `DATA_LICENSE.md`

**Interfaces:**
- Consumes: verified firmware constants, MATLAB parameters, presentation claims, resume facts, extracted images, and repository paths.
- Produces: the public project landing page and explicit code/non-code licensing boundaries.

- [ ] **Step 1: Replace the placeholder README with the approved structure**

Write an English-first README with concise Chinese deployment notes. Include the hardware photograph, architecture, bill of materials, GPIO table, serial and Wi-Fi packet layouts, electrode placement, safety warning, startup sequence, MATLAB setup, Web client setup, signal-processing pipeline, data format, demonstrations, team credits, and repository tree.

- [ ] **Step 2: State evidence and limitations precisely**

Identify 95.1% as the presentation-reported window-level holdout result. Explain overlapping-window leakage, absence of subject-independent validation, missing browser JSON export, preprocessing mismatch between browser inference and MATLAB training, and the lack of current hardware verification.

- [ ] **Step 3: Add licensing files**

Use the standard MIT text for original source code. State in `DATA_LICENSE.md` that the recordings, model, presentation, images, and videos are publicly viewable but receive no additional reuse or redistribution license.

- [ ] **Step 4: Validate README paths and technical constants**

Use a script to extract every relative Markdown link and confirm its target exists. Search firmware and MATLAB files for each value documented in README: pins 4/5/6, 1000 Hz, 921600 baud, WebSocket port 81, batch size 25, 200 ms window, 50 ms stride, threshold 0.005, four gestures, and linear one-vs-one ECOC-SVM.

- [ ] **Step 5: Commit public documentation**

```powershell
git add README.md LICENSE DATA_LICENSE.md
git diff --cached --check
git commit -m "docs: document hardware deployment and reproducibility"
```

### Task 5: Final Verification and Publication

**Files:**
- Verify: all tracked repository files
- Update if necessary: documentation-only defects found by verification

**Interfaces:**
- Consumes: Tasks 1-4 and the remote `origin/main` branch.
- Produces: a verified local `main` commit and a normal push to the specified GitHub repository.

- [ ] **Step 1: Run repository integrity checks**

Run `git status --short`, `git diff --check origin/main..HEAD`, `git log --oneline --decorate`, `git lfs ls-files`, file-count checks, link checks, and a secret-pattern scan. Confirm no legacy duplicate directories remain.

- [ ] **Step 2: Run available source checks**

Check HTML/JavaScript structure with locally available tooling, perform brace/protocol consistency checks on both Arduino sketches, and use MATLAB/Octave syntax tooling only if installed. Record unavailable runtime checks rather than inferring success.

- [ ] **Step 3: Review scientific and privacy boundaries**

Confirm the README contains no unsupported clinical, cross-subject, or generalization claim; all requested team names and public artifacts are intentional; and network credentials are documented as demonstration defaults that users must change.

- [ ] **Step 4: Fetch and verify fast-forward publication safety**

Run `git fetch origin main`, verify `git merge-base --is-ancestor origin/main HEAD`, and stop if the remote has advanced outside the local history.

- [ ] **Step 5: Push and verify the remote commit**

Run `git push origin main`, then `git ls-remote origin refs/heads/main`. Confirm the returned SHA equals local `HEAD` and verify Git LFS reports no missing upload.

- [ ] **Step 6: Report verification evidence and limitations**

Summarize files changed, hardware deployment design, commands actually executed, remote URL/commit, and all checks not run because MATLAB, ESP32 hardware, or toolchains were unavailable.
