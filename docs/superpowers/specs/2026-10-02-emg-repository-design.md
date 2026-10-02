# Three-Channel sEMG Repository Design

## Goal

Convert the existing BME3201 course-project folder into a public, self-contained
Git repository whose README emphasizes reproducible hardware deployment. Preserve
the current acquisition, signal-processing, classification, desktop, and web
implementations without changing their scientific behavior.

## Current System

The project contains two ESP32-S3 acquisition paths, a MATLAB App Designer
desktop application, a MATLAB training script, a saved ECOC-SVM model, raw
three-channel recordings, a browser client, a presentation, and two demonstration
videos.

The implemented signal path is:

1. Three analog biosignal sensor modules feed ESP32-S3 ADC pins 4, 5, and 6.
2. The serial firmware samples at 1 kHz and transmits a 10-byte frame at 921600
   baud. The frame contains a CR/LF header followed by a 16-bit counter and three
   16-bit ADC values in little-endian order.
3. The Wi-Fi firmware creates the `ESP32-EMG-Host` access point and broadcasts
   batches of 25 samples through a WebSocket server on port 81. Each sample is an
   8-byte packed record containing the same four 16-bit fields.
4. MATLAB records labeled three-channel data, applies the configured filters,
   extracts MAV, WL, ZC, and SSC features from 200 ms windows with a 50 ms stride,
   and classifies Rest, Fist, Grasp, and Scissor using a linear one-vs-one
   ECOC-SVM.
5. The browser client displays three live channels, records CSV data, and contains
   a JSON-model inference path.

## Chosen Approach

Use a conservative repository conversion. Reorganize files, remove the duplicate
presentation, repair paths affected by the move, add documentation and repository
metadata, and preserve algorithmic behavior. Do not retrain the model, change
filters, alter the classifier, or replace the evaluation protocol in this task.

## Target Structure

```text
.
├── firmware/
│   ├── serial/serial_tx_bin.ino
│   └── wifi/wifi_emg.ino
├── matlab/
│   ├── EMG_recognition.mlapp
│   ├── Train_EMG_Model.m
│   ├── getEMGFeatures.m
│   └── MyTrainedModel.mat
├── web/index.html
├── data/raw/*.mat
├── docs/
│   ├── images/
│   ├── media/
│   ├── presentation/EMG.pptx
│   └── superpowers/
├── README.md
├── LICENSE
├── DATA_LICENSE.md
├── .gitignore
└── .gitattributes
```

The MATLAB training script will resolve paths from its own file location so it
can read `data/raw` and write the trained model into `matlab/` regardless of the
shell working directory. The App Designer file, feature function, and saved model
remain together because the current app loads the model and function by name.

## README Design

The README will use English as its primary language with concise Chinese guidance
for hardware deployment. Its visual and narrative order will be:

1. Project title, one-sentence scope, hardware photograph, and supported gestures.
2. System architecture and the two supported communication paths.
3. A hardware deployment section covering parts, GPIO wiring, electrode placement,
   electrical-safety boundaries, serial framing, Wi-Fi framing, and startup order.
4. MATLAB desktop setup, model training, data recording, and live recognition.
5. Browser/mobile setup, CSV recording, and the limitation that a compatible JSON
   export is required for browser-side inference.
6. Signal-processing and classification details with exact implemented parameters.
7. Repository structure, data format, demonstrations, team credits, licensing, and
   reproducibility limitations.

Actual hardware photographs will be extracted from the supplied presentation and
stored under `docs/images/`. The original presentation and both videos will remain
available as project artifacts.

## Scientific Integrity Boundaries

The presentation reports 95.1% accuracy. The training script creates overlapping
windows first and then uses a random 80/20 holdout at window level. Neighboring
windows from the same recording may therefore occur in both partitions. The
README must label 95.1% as the course-presentation result under this window-level
protocol and must not claim record-independent, subject-independent, clinical, or
deployment-level generalization.

The browser inference path does not implement the same filtering pipeline as the
MATLAB trainer and no compatible JSON model is currently present. The README must
separate verified waveform display and CSV logging from browser inference and
describe this mismatch as a current limitation.

The device is a research and teaching prototype. Documentation must state that it
is not a medical device and must not advise connection to a person while the
system is connected to unsafe or non-isolated power.

## Repository and Licensing Policy

All requested artifacts will be published. Git LFS will track binary research and
media artifacts, including MAT, MLAPP, MP4, and PPTX files. The duplicate PPTX
will be removed before tracking. The MIT License will cover original source code
only. `DATA_LICENSE.md` will state that public access to the data, model,
presentation, images, and videos does not grant an additional reuse or
redistribution license.

The local repository will preserve the existing remote `main` history rather than
force-pushing over it.

## Validation

Before publication:

- confirm every target file exists and the duplicate presentation is absent;
- verify README links and media paths;
- verify firmware protocol descriptions against both `.ino` files;
- check the MATLAB training script and feature function for syntax-level issues
  where local tooling permits;
- verify Git LFS patterns and tracked objects;
- inspect the staged diff for accidental local files or secrets;
- verify the local branch contains the remote `main` commit;
- push normally and confirm the remote branch commit.

MATLAB execution, ESP32 compilation, and end-to-end hardware tests require tools
and hardware that may not be available in this environment. Any unexecuted checks
will be reported explicitly.

## Out of Scope

- retraining or replacing the saved model;
- changing the current filtering, feature extraction, classifier, or labels;
- claiming improved accuracy or generalization;
- implementing a new JSON exporter or redesigning browser inference;
- manufacturing a PCB or providing a medical-device safety certification.
