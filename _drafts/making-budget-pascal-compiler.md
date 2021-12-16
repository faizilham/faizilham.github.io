---
layout: post
title: Making a budget Pascal compiler to WebAssembly
tags: compiler web-assembly
---

*TL;DR: I made a budget Pascal compiler to WebAssembly so that I can play a hangman game that my friends and I made 10 years ago. Check out the [demo](https://faizilham.github.io/lab/budget-pascal/#hangman) and the [github repository](https://github.com/faizilham/budgetpascal).*

About a month ago, I was reorganizing my old files in my laptop when I found something interesting. It was a console-based hangman game that my friends and I made in Pascal as a final project for intro to programming class[^1] back in 2011. At the time I had just finished reading [Crafting Interpreters](https://craftinginterpreters.com/) by Robert Nystrom, so I thought it would be fun to move to compilers and try to compile the hangman game to WebAssembly. Here are some interesting things I learned and made during the development.

### Chosen features
Making a full-fledge Pascal compiler is a very time-consuming task. I want the project to be small enough that I can finish it in 4-6 weeks, so I decided to support only a subset of Pascal features and language constructs (hence, "budget"). I chose which features to implement based on three principles:
1. The compiler should be able to compile the hangman game without any changes to the game's source code. This means I need to handle things that normally I don't handle like files, output formatting, standard library methods like `pos`, `clrscr`, `readkey`, and so on.
2. The compiler should be able to handle things that are "naturally" exist given the chosen features. For example, while the game source code doesn't have any recursion call or use any floating-point number type, I think it would be weird not implementing those. However, things like dynamic length array, dynamic memory allocation, pointers, and fully-implemented set type are surplus to the requirements. This rationale is quite arbitrary but I settled on it.
3. The compiler should compile a strict subset of Pascal. This means while it can't compile some Pascal programs, all programs that it can compile should be compilable by other full-feature Pascal compiler like FreePascal. There should be no program that is valid for this compiler but invalid for other compilers. This is easier said than done and I'm still not 100% sure if the implementation is indeed a strict subset.

The full detail of chosen features can be found in the [repository's readme](https://github.com/faizilham/budgetpascal#which-subset-of-pascal). In summary, the compiler can handle:
- Basic data types like `integer`, `real`, `char`, `boolean`, `string`, `array`, `record` and `file`
- Variable, constant, type alias, and subroutine (procedure / function) declaration
- Basic expression, subroutine call and control flow statement
- Internal declaration (e.g. procedure inside procedure) with local / global scoping
- A few standard library method call

### Generating WebAssembly binary
I wanted the hangman game to be playable on a web page. There are three approaches[^2] to do it: (1) make a virtual machine that interprets and runs the Pascal program, (2) transpile the Pascal program to Javascript and then run it using [Function object](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/Function), and (3) compile the Pascal program to WebAssembly. I chose the third option because I'm interested in WebAssembly for quite some time and it seems more fun and challenging than "just" making a VM or transpiling to Javascript.

While it is possible to just manually produce WebAssembly binary bytecodes, I used the [binaryen-js](https://github.com/AssemblyScript/binaryen.js/) library because it's easier and it also have validation and optimization features. The downside is that it is quite large, about 5 MB even after packed using parceljs. It also uses tree representation for validating and optimizing the WebAssembly module, so a few expressions like multivalue tuples and manual stack manipulation are a little bit harder to express. At the time I didn't realize there's also [wabt.js](https://github.com/AssemblyScript/wabt.js), so it is possible to produce WebAssembly code in text format first and then convert it to binary format.

### Implementing types and variable scope
WebAssembly has concept for local variable, so locally-used variable can be implemented using that. However, it can only store integer or float value. For basic types the compiler can just directly use `f64` variable for real and `i32` variable for ordinals (integer, char, boolean), but for complex type like string, array, or record, it needs to maintain a call stack in the memory and store the address of the value as an `i32` local variable. Values in the call stack are allocated when a subroutine is called, and deallocated when the subroutine returns. The call stack is implemented in three parts:
1. Two global variable SP (stack pointer) and (FP) frame pointer. SP stores an address to top of value stack, and FP stores an address to top of call frame stack.
2. Value stack, a region of the memory that stores complex type values.
3. Call frame stack, a region of the memory that stores base address of the value stack for that call and subroutine id.

Consider the following pascal program:
```pascal
program test;
    type SmallStr = string[9];
    var str: SmallStr;

    procedure a(strA: SmallStr);
    begin
        // ...
    end;

    procedure b(strB: SmallStr);
    var strB1: SmallStr;
    begin
        // ...
        a(strB);
    end;

begin
    b(str);
end.
```

When procedure `a` is called, the call frame and value stack would look something like this in memory.
![image](/img/2021/budget-pascal-stack.png)

Things are a little more complicated for non-locally used variable. One of the limitation of WebAssembly local variable is that it can't be referenced as a pointer from outside of that function that declare it. So all non-locally used variable must be stored in memory no matter the type. This includes using upper-scope variable and using variable as an argument to a var parameter.

#### Footnotes

[^1]: PTI-A class, for those who were pre-2012 ITB students. If I remember correctly, the class was reorganized into PTI-B and DasPro classes for CS & EE students due to a syllabus change in 2012.
[^2]: I'm fully aware that there is a way to [compile Pascal to WebAssembly using FreePascal](https://wiki.freepascal.org/WebAssembly/Compiler) and maybe a lot more other ways, but I also want to make a compiler!
