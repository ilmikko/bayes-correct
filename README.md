This project researches ways of detecting what the user is doing by the raw activities on the keyboard.
Hence you might understand that another name candidate for the project was 'definitely-not-a-keylogger'.

== Usage ==

At the moment only the keystrokes from the linux kernel are supported.
You can pipe the input events directly into this program by running:
`~# cat /dev/input/event0 | ruby bayes.rb`

I'll add a possibility of direct input (to stdin) later.

== The idea ==

The idea comes from the fact that people hate to learn different key combinations for different commands. From the top of my head I can make a couple of examples:

* CTRL+LEFTARROW => Seek word to the left
* CTRL+A => Select all
* CTRL+F => Find
* ALT+F4 => Close a window
* TAB => Move to next field

You don't necessarily need to know anything of the interface the user is using - if they type `CTRL+F CAT` I can be 99% sure that they are searching for the word 'cat'.

But probably the most interesting bit (for me) would be correcting typing mistakes. I notice that when I'm in my 'typing' mode, when I make a mistake I press backspace and correct the mistake I make. This might sound like a nobrainer, but it's a pattern for the computer to follow.

Take the following example of typing.

`Monopool<BS><BS>oly`

What does this tell us (the program)?
It tells us that we have made a mistake (monopool) and we have corrected this mistake (monopoly).
This means the next time the user types this mistake (or maybe something similar), we can try and correct the user's mistake!

That's basically the core of the idea.
