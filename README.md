[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/O6r6ltSE)
# Lab 1 — Bare-Metal GPIO on STM32 NUCLEO-F412ZG

[![Hardware](https://img.shields.io/badge/Hardware-STM32_NUCLEO--F412ZG-03234B.svg?logo=stmicroelectronics&logoColor=white)](https://www.st.com/en/evaluation-tools/nucleo-f412zg.html)
[![Toolchain](https://img.shields.io/badge/Toolchain-arm--none--eabi--gcc-A8B9CC.svg?logo=arm&logoColor=white)](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
[![GitHub Classroom](https://img.shields.io/badge/GitHub-Classroom-181717.svg?logo=github)](https://classroom.github.com/classrooms/274591709-mmue-arquitectura-sistemas-embebidos-2026)

---

## Table of Contents

- [Context](#context)
- [Objectives](#objectives)
- [Expected Result](#expected-result)
- [Hardware](#hardware)
- [Documentation to Consult](#documentation-to-consult)
- [Workflow with GitHub Classroom](#workflow-with-github-classroom)
- [Repository Structure](#repository-structure)
- [Student Tasks](#student-tasks)
- [Suggested Milestones](#suggested-milestones)
- [Development Environment](#development-environment)
- [Reference Technical Sequence](#reference-technical-sequence)
- [Common Errors](#common-errors)
- [Rubric](#rubric)

---

## Context

This lab introduces the minimum firmware development workflow for embedded systems using an STM32 NUCLEO-F412ZG board and **bare-metal** development, without HAL, without CubeMX, and without a complex build system.

The board includes an ST-LINK programmer and debugger, so it can be programmed directly without additional external hardware.

This lab is intended as the basis for the rest of the course laboratories. The same repository will evolve in later labs: software architecture, testing, static analysis, debugging, and product variants.

---

## Objectives

By the end of this lab, students should be able to:

- Consult the NUCLEO user manual and the microcontroller Reference Manual to extract hardware and register information.
- Build firmware with the Arm toolchain from the command line.
- Flash and run a binary on the board.
- Implement a basic GPIO driver to read a button by polling and control an LED.
- Work on a GitHub repository with frequent commits and clear messages.

---

## Expected Result

The final program reads the user button B1 and turns the user LED LD2 on or off by polling:

- **B1** → Pull-up button: high level at rest, low level when pressed
- **LD2** → Blue LED: high level = ON

---

## Hardware

- STM32 NUCLEO-F412ZG
- USB-A to Mini-B cable for power and ST-LINK
- CN4 jumpers in ON position (default configuration to program the MCU on the board itself)

---

## Documentation to Consult

This lab requires the use of real documentation. Download the documents from the course virtual campus before starting:

| Document                            | Use in This Lab                          |
| ----------------------------------- | ---------------------------------------- |
| UM1974 — Nucleo-144 User Manual     | Locate LED, button, jumpers, and ST-LINK |
| STM32F412ZG Datasheet               | Identify package and pins                |
| RM0402 — STM32F412 Reference Manual | Memory map, RCC, and GPIO                |

## Workflow with GitHub Classroom

The course uses **GitHub Classroom** for lab management and submission. Each student receives an individual copy of the template repository when accepting the assignment.

### How to Start

1. Access the assignment link published by the instructor in the virtual campus.
2. Accept the assignment in GitHub Classroom — a private repository in your name will be created automatically.
3. Clone your repository locally:

   ```bash
   git clone https://github.com/<org>/<assigned-repo>.git
   cd <assigned-repo>
   ```

4. Work on that repository. Each functional milestone should be one commit.

### Automatic Feedback

The repository includes two GitHub Actions workflows that run on every `push`:

| Workflow                         | What It Checks                      |
| -------------------------------- | ----------------------------------- |
| Lab 1 — Guided Questions Grading | Answers in `answers.env`            |
| Lab 1 — Build Verification       | That the code builds without errors |

Check the results in the **Actions** tab of your repository. You may push as many times as needed—each push updates the feedback.

### Commit Conventions

- One commit per functional milestone (LED blinks, button detected, driver complete, etc.).
- Short, technical, lowercase commit messages:

```text
feat: implement gpio_config_output
fix: correct MODER mask for PB7
docs: complete guided question answers
```

Do not upload binary files (`*.elf`, `*.bin`, `*.o`) — they are already included in `.gitignore`.

### Submission

Submission is automatic: the instructor accesses each student's repository in the GitHub Classroom organization. You do not need to create a pull request or send anything by email. Make sure your final submission commit has been pushed before the deadline.

---

## Repository Structure

```text
Repository root/
├── README.md
├── answers.env              ← fill in your answers to the guided questions
├── .gitignore
├── docs/
│   └── guided_test.md    ← documentation questions (read before coding)
├── inc/
│   ├── board.h                 ← TODO: pin and port mapping
│   ├── rcc.h                   ← TODO: clock masks (RCC_AHB1ENR)
│   └── gpio.h                  ← complete — addresses and driver declarations
├── src/
│   ├── gpio.c                  ← TODO: GPIO driver implementation
│   └── main.c                  ← TODO: initialization and polling loop
├── startup/
│   └── startup_stm32f412zg.s   ← complete — vector table and Reset_Handler
├── linker/
│   └── stm32f412zg.ld          ← complete — linker script
└── scripts/
    ├── build.sh                ← builds and generates ELF/BIN/HEX
    ├── flash.sh                ← programs the board via ST-LINK
    └── check_answers.sh        ← local answer checker (CI-related use)
```

Files marked as **complete** are part of the template and must not be modified. Files marked as **TODO** are the ones you must implement.

---

## Student Tasks

### Part 1 — Guided Documentation Questions

Before writing code, read [docs/guided_test.md](docs/guided_test.md) and fill in [answers.env](answers.env) with the values you find in the technical documentation.

The automatic grader checks your answers on every `push` and tells you what is correct, what is incorrect, and where to look.

### Part 2 — `inc/board.h`

Fill in the macros with the correct pins and ports for B1 and LD2 according to UM1974 and your answers from Block 1:

```c
#define B1_PIN    /* pin number */
#define B1_PORT   /* GPIOX_BASE */
#define LD2_PIN   /* pin number */
#define LD2_PORT  /* GPIOX_BASE */
```

### Part 3 — `inc/rcc.h`

Fill in the clock enable masks according to RM0402 and your answers from Block 3:

```c
#define RCC_AHB1ENR_GPIOBEN   /* (1U << ?) */
#define RCC_AHB1ENR_GPIOCEN   /* (1U << ?) */
```

### Part 4 — `src/gpio.c`

Implement the five driver functions. Each function includes a `TODO` comment with the steps and references to the corresponding guided-question block:

| Function             | Reference Block         |
| -------------------- | ----------------------- |
| `gpio_enable_clock`  | Block 3 — `RCC_AHB1ENR` |
| `gpio_config_input`  | Block 4 — `GPIOx_MODER` |
| `gpio_config_output` | Block 4 — `GPIOx_MODER` |
| `gpio_read`          | Block 5 — `IDR`         |
| `gpio_write`         | Block 5 — `BSRR`        |

### Part 5 — `src/main.c`

Complete the four `TODO` items in `main`:

- Enable the clock for the ports used.
- Configure LD2 as output.
- Configure B1 as input.
- Polling loop: read B1 and control LD2 directly.

### Part 6 — Verification on Hardware

#### Flashing from Command Line

```bash
bash scripts/build.sh   # build → output/lab1.elf
bash scripts/flash.sh   # program the board
```

#### Flashing from VS Code

`Ctrl+Shift+P` → _Tasks: Run Task_ → **flash** — builds and flashes in one step.

#### Debugging in VS Code

Press `F5` — builds, flashes, and opens a debug session that stops at the start of `main()`.

| Key          | Action                      |
| ------------ | --------------------------- |
| **F10**      | Step over                   |
| **F11**      | Step into                   |
| **F5**       | Continue to next breakpoint |
| **Shift+F5** | Stop                        |

See [debug/README.md](debug/README.md) for more details on what you can inspect during debugging.

Verify that the blue LD2 LED turns on when B1 is pressed and turns off when it is released.

## Suggested Milestones

Work incrementally — one commit per milestone:

| Milestone                 | Success Criterion on Hardware                                                                      |
| ------------------------- | -------------------------------------------------------------------------------------------------- |
| H1 — Fixed LED            | LD2 turns on at startup (temporarily write to ODR from `main`; H2 replaces this with `gpio_write`) |
| H2 — Complete GPIO Driver | The driver functions work correctly                                                                |
| H3 — Button Controls LED  | B1 turns LD2 on and off by polling                                                                 |

## Development Environment

- Editor: VS Code (recommended) or any text editor.
- Operating system: WSL on Windows, or native Linux.
- Toolchain: `arm-none-eabi-gcc` — install with `sudo apt install gcc-arm-none-eabi`.
- Programmer / debugger: OpenOCD — `sudo apt install openocd` (Linux/WSL) or [gnutoolchains.com/arm-eabi/openocd](https://gnutoolchains.com/arm-eabi/openocd/) (Windows; preinstalled on lab machines).
- Version control: Git + GitHub Classroom.

---

## Reference Technical Sequence

1. Read UM1974 → identify B1 and LD2 pins.
2. Read RM0402 → memory map → obtain RCC, GPIOB, and GPIOC base addresses.
3. Read RM0402 → `RCC_AHB1ENR` → calculate enable masks.
4. Read RM0402 → `GPIOx_MODER` → calculate field and mask for each pin.
5. Read RM0402 → `IDR` / `BSRR` → implement read and write.
6. Build → flash → verify on hardware.

---

## Common Errors

- Not enabling the GPIO clock before accessing its registers.
- Confusing pin number with bit number in `MODER` (they are different: `MODER` uses 2 bits per pin).
- Misinterpreting the active level of the button when reading `IDR`.
- Using documentation from another STM32 family.
- Uploading binary files to the repository (use `.gitignore`).

## Rubric

| Criterion                          | Weight |
| ---------------------------------- | -----: |
| Correct answers in `answers.env`   |    40% |
| Error-free build                   |    20% |
| Correct behavior on hardware       |    20% |
| Correct GPIO driver implementation |    10% |
| Commit quality and submission      |    10% |
