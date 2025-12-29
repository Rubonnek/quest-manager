# Quest Manager

<img src="icon.svg" width="128" height="128">

![GitHub Release](https://img.shields.io/github/v/release/Rubonnek/quest-manager?label=Current%20Release)
![Github Downloads](https://img.shields.io/github/downloads/Rubonnek/quest-manager/total?logo=github&label=GitHub%20Downloads)

A powerful and flexible quest management system for the Godot Game Engine, enabling developers to create hierarchical quest trees, track detailed quest states and progress, and integrate custom conditions and metadata for dynamic gameplay experiences.

## :star: Features

- :evergreen_tree: Create hierarchical quest trees with ease in GDScript
- :white_check_mark: Track comprehensive quest states: active, accepted, rejected, completed, failed, canceled
- :gear: Add custom conditions using Callables for state transitions (acceptance, rejection, completion, failure, cancelation)
- :label: Attach metadata to quests for storing additional custom data
- :signal_strength: Signals for quest events (activated, accepted, rejected, canceled, completed, failed, updated)
- :chart_with_upwards_trend: Built-in progress tracking across all quests
- :art: Easy to customize -- bring your own GUI nodes
- :hammer_and_wrench: Integrated quest viewer for tracking and debugging quests at runtime with ease
- :floppy_disk: Serialization support for saving and loading quest data

## :zap: Requirements

- Godot 4.2.1+

## :rocket: Getting Started

- Clone/[download](https://github.com/Rubonnek/quest-manager/archive/refs/heads/master.zip) the repository and check out the demos!

## :package: Installation

[Download](https://github.com/Rubonnek/quest-manager/archive/refs/heads/master.zip) or clone this repository and copy the contents of the
`addons` folder to your own project's `addons` folder, and enable the `Quest Manager` plugin in the Project Settings.
