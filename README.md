# Project 5 - Trivia Challenge

Submitted by: **Ritch Barlatier**

**Trivia Challenge** is a SwiftUI trivia game that lets players customize a quiz, answer questions from the Open Trivia Database, and receive immediate results after submitting their answers. The app also includes an offline question fallback so a game can still be played when the trivia service is unavailable.

Time spent: **6 hours** spent in total

## Required Features

The following **required** functionality is completed:

- [x] App launches to an Options screen where the user can modify the types of questions presented when the game starts. Users can choose:
  - [x] Number of questions
  - [x] Category of questions
  - [x] Difficulty of questions
  - [x] Type of questions (Multiple Choice or True/False)
- [x] User can tap a button to start the trivia game, which presents questions and answers in a card view.
- [x] Selected choices are visually marked as the user taps an answer without revealing whether it is correct.
- [x] User can submit all choices and is presented with their final score.

## Optional Features

The following **optional** features are implemented:

- [x] Answers are marked as correct or incorrect after the user submits the quiz.
- [x] A configurable timer automatically submits the quiz when time expires.

## Additional Features

- [x] Live trivia questions are loaded from the Open Trivia Database API.
- [x] An offline question fallback keeps the app playable during network interruptions.
- [x] A progress indicator shows how many questions have been answered.
- [x] Players can select a 30-second, 1-minute, 2-minute, or 3-minute time limit.
- [x] Users can retry loading a quiz after an error.
- [x] The interface includes a gradient background, glass-style panels, animated symbols, and responsive question cards.
- [x] Answer choices include accessibility labels and selected-state descriptions.
- [x] Questions and answer choices support percent-decoded text from the API.

## Video Walkthrough

Here's a walkthrough of the implemented user stories:

[Watch the Trivia Challenge video walkthrough on Loom](https://www.loom.com/share/32c626ee9cd649c09aa6fe28c7d49808)

For help embedding a Loom video on GitHub, see the [walkthrough guide](https://www.youtube.com/watch?v=GA92eKlYio4).

## Notes

One challenge was handling network access in a sandboxed macOS app. The app target needed permission to make outgoing network connections before it could reach the trivia API. Another challenge was making the game remain usable when the service or DNS was unavailable, which was handled by adding a local fallback question set and a retry state.

The UI was also designed to clearly separate answer selection from answer evaluation: selections are highlighted while playing, but correct and incorrect answers are revealed only after submission.

## License

    Copyright 2026 Ritch Barlatier

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
