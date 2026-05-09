# Lab 1 — Guided Documentation Questions

Before writing any code, you must fill in the [`answers.env`](../answers.env) file with the answers to these questions. Each answer has a fixed key that the grading system checks automatically.

**Documents you need:**

- **UM1974** — STM32 Nucleo-144 user manual (board hardware)
- **STM32F412ZG Datasheet** — Package and pinout
- **STM32F412 Reference Manual (RM0402)** — Memory map, RCC, and GPIO

---

## Block 1 — Board hardware

> Source: UM1974

**Q1.1** Which microcontroller pin is the user button B1 connected to?
→ Key: `B1_PIN` (format: port letter + number, e.g. `PA5`)

**Q1.2** Which microcontroller pin is the user LED LD2 connected to?
→ Key: `LD2_PIN`

**Q1.3** What logic level does the button pin have when it is **not** pressed? And when it **is** pressed?
→ Keys: `B1_IDLE_LEVEL` and `B1_PRESSED_LEVEL` (values: `0` or `1`)

---

## Block 2 — Memory map

> Source: RM0402, section "Memory map"

**Q2.1** What is the base address of RCC?
→ Key: `RCC_BASE` (hex format with `0x` prefix, e.g. `0x40000000`)

**Q2.2** What is the base address of GPIOB?
→ Key: `GPIOB_BASE`

**Q2.3** What is the base address of GPIOC?
→ Key: `GPIOC_BASE`

---

## Block 3 — Clock enable (RCC_AHB1ENR)

> Source: RM0402, RCC section → RCC_AHB1ENR register

**Q3.1** What bit number enables the GPIOB clock in RCC_AHB1ENR?
→ Key: `GPIOBEN_BIT` (integer, e.g. `0`)

**Q3.2** What bit number enables the GPIOC clock?
→ Key: `GPIOCEN_BIT`

**Q3.3** What is the hex mask to enable both ports at once?
→ Key: `AHB1ENR_MASK` (hex with `0x` prefix)

---

## Block 4 — Pin mode (GPIOx_MODER)

> Source: RM0402, GPIO section → GPIOx_MODER

**Q4.1** How many bits does each pin's mode field occupy in MODER?
→ Key: `MODER_BITS_PER_PIN` (integer)

**Q4.2** What value (decimal) configures a pin as **input**?
→ Key: `MODER_INPUT_VAL`

**Q4.3** What value (decimal) configures a pin as **general-purpose output**?
→ Key: `MODER_OUTPUT_VAL`

**Q4.4** At which bit position (least significant bit of the pair) does the mode field for PB7 start within GPIOB_MODER?
→ Key: `PB7_MODER_BIT` (integer)

**Q4.5** At which bit position does the mode field for PC13 start within GPIOC_MODER?
→ Key: `PC13_MODER_BIT`

---

## Block 5 — Read and write (IDR / ODR)

> Source: RM0402, registers GPIOx_IDR and GPIOx_ODR

**Q5.1** What is the offset of IDR within a GPIO register block?
→ Key: `IDR_OFFSET` (hex with `0x` prefix)

**Q5.2** What is the offset of ODR?
→ Key: `ODR_OFFSET`

**Q5.3** Which bit number of GPIOC_IDR corresponds to PC13?
→ Key: `PC13_IDR_BIT`

**Q5.4** Which bit number of GPIOB_ODR corresponds to PB7?
→ Key: `PB7_ODR_BIT`

---

## Submission instructions

1. Fill in [`answers.env`](../answers.env) with all values.
2. Commit with a clear message, for example:

   ```text
   docs: complete guided questions answers for lab1
   ```

3. Push. The grader will run automatically.
4. Check the result in the **Actions** tab of your repository → workflow **Lab 1 — Guided Questions Grading**.

If anything fails, you will see a hint below each incorrect answer. Fix it, make another commit, and push again — you can retry as many times as needed.
