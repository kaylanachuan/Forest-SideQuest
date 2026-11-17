VAR items = 3
-> big_red

=== big_red ===
You: "Hi, do you know which bridge will lead me to the flower field?"

BigRed: "Why yes I do, but first you have to solve my riddle if you want to cross any of my bridges."

You: "Okay, shoot."

-> riddle

=== riddle ===
BigRed: "What can you hold but can't touch?"

* [A shadow]
    You: "A shadow."
    -> riddle_wrong
* [A promise]
    You: "A promise."
    BigRed: "CORRECT! Good job, take the left bridge, and here's an item back since you got it correct."
    ~ items = items + 1
    -> END
* [A flower]
    You: "A flower."
    -> riddle_wrong

=== riddle_wrong ===
BigRed: "WRONG! This riddle is so easy, I'm taking an item from you as punishment."
~ items = items - 1
{ items <= 0:
    You have nothing left. Your bravery crumbles and you collapse from anxiety.
    @@GAMEOVER@@
        -> END
}
// Wrong answers loop back so you can try again
-> riddle