---
layout: post
title: Making a budget Pascal compiler to WebAssembly
tags: compilers web-assembly
---

*TL;DR: I made a budget Pascal compiler to WebAssembly so that I can play a hangman game that my friends and I made 10 years ago. Checkout the [demo](https://faizilham.github.io/lab/budget-pascal/#hangman) and the [github repository](https://github.com/faizilham/budgetpascal).*

About a month ago, I was reorganizing my old files in my laptop when I found something interesting. It was a console-based hangman game that my friends and I made in Pascal as a final project for intro to programming class[^1] back in 2011. At the time I had just finished reading [Crafting Interpreters](https://craftinginterpreters.com/) by Robert Nystrom, so I thought it would be fun to move to compilers and try to compile the hangman game to WebAssembly. Here are some interesting things I found and implemented during the development.

### Choosen features
Making a full-fledge Pascal compiler is a very time-consuming task. I want the project to be small enough that I can finish it in 4-6 weeks, so I decided to support only a subset of Pascal features and language constructs (hence, "budget"). I chose which features to implement based on three principles:
1. The compiler should be able to compile the hangman game without any changes to the game's source code. This means I need to handle things that normally I don't handle like files, output formatting, standard library methods like `pos`, `clrscr`, `readkey`, and so on.
2. The compiler should be able to handle things that are "naturally" exist given the chosen features. For example, while the game source code doesn't have any recursion call or use any floating-point number type, I think it would be weird not implementing those. However, things like dynamic length array, dynamic memory allocation, and fully-implemented set type are surplus to the requirements. It is still quite arbitrary but I'm okay with that.
3. The compiler should compile a strict subset of Pascal. This means while it can't compile some Pascal programs, all programs that it can compile should be compilable by other full-feature Pascal compiler like FreePascal. There should be no program that the compiler can compile, but will produce error in other compilers. This is easier said than done and I'm still not 100% sure if the implementation is indeed a strict subset.

The full detail of chosen features can be found in the [repository's readme](https://github.com/faizilham/budgetpascal#which-subset-of-pascal). In summary, the compiler can handle:
- Basic data types like `integer`, `real`, `char`, `boolean`, `array`, `record` and `file`
- Variable, constant, type alias, and subroutine (procedure / function) declaration
- Basic expression, subroutine call and control flow statement
- Internal declaration (e.g. procedure inside procedure) with local / global scoping
- A few standard library method implementation



Footnotes:

[^1]: PTIA (Pengenalan Teknologi Informasi A), for those who were pre-2012 ITB students. The class was replaced with Dasar Pemrograman (Daspro) due to a syllabus change in 2012.
