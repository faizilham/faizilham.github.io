---
layout: post
title: Making a budget Pascal compiler to WebAssembly
tags: compiler web-assembly
---

*TL;DR: I made a budget Pascal compiler to WebAssembly so that I can play a hangman game that my friends and I made 10 years ago. Check out the [demo](https://faizilham.github.io/lab/budget-pascal/#hangman) and the [github repository](https://github.com/faizilham/budgetpascal).*

About a month ago, I was reorganizing my old files in my laptop when I found something interesting. It was a console-based hangman game that my friends and I made in Pascal as a final project for intro to programming class[^1] back in 2011. I had just finished reading [Crafting Interpreters](https://craftinginterpreters.com/) by Robert Nystrom, so I thought it would be fun to move to compilers and try to compile the hangman game to WebAssembly. Here are some of many interesting things I learned and made during the development.

### Choosing and "budgeting" the features
Making a full-fledge Pascal compiler is a very time-consuming task. I want the project to be small enough that I can finish it in 4-6 weeks, so I decided to support only a subset of Pascal features and language constructs (hence, "budget"). I chose which features to implement based on three principles:
1. The compiler should be able to compile the hangman game without any changes to the game's source code. This means I need to handle things that normally I don't handle like files, output formatting, standard library methods like `pos`, `clrscr`, `readkey`, and so on.
2. The compiler should be able to handle things that "naturally" exist given the chosen features. For example, while the game source code doesn't have any recursion call or use any floating-point number type, I think it would be weird not implementing those. However, things like dynamic length array, dynamic memory allocation, pointers, and fully-implemented set type are surplus to the requirements. This rationale is quite arbitrary but I settled on it.
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

### Variables and call stack
WebAssembly has concept for [local variable](https://webassembly.github.io/spec/core/syntax/instructions.html#variable-instructions), so locally-used variable can be implemented using it. However, it can only store integer or float value. For basic types the compiler can just directly use `f64` variable for real and `i32` variable for ordinals (integer, char, boolean), but for complex type like string, array, or record, it needs to maintain a call stack in the memory and store the address of the value as an `i32` local variable. Values in the call stack are allocated when a subroutine is called, and deallocated when the subroutine returns. The call stack is implemented in three parts:
1. Two global variable SP (stack pointer) and (FP) frame pointer. SP stores an address to top of value stack, and FP stores an address to top of call frame stack.
2. Value stack, a region of the memory that stores complex type values.
3. Call frame stack, a region of the memory that stores base address of the value stack for that call and subroutine id.

Let's look at the following Pascal program.
```pascal
program test;
    type SmallStr = string[9];
    var str: SmallStr;
        x: integer;

    procedure a(strA: SmallStr; z: char);
    begin
        // ...
    end;

    procedure b(strB: SmallStr);
    var strB1: SmallStr;
        y: boolean;
    begin
        // ...
        y := false;
        a(strB, 'a');
    end;

begin
    b(str);
end.
```

When procedure `a` is called, the call frame and value stack would look something like this in memory. Notice that variables `x`, `y` and `z` are not manually stored in the memory.

<picture>
  <source srcset="/img/2021/budget-pascal-stack-dark.png" media="(prefers-color-scheme:dark)">
  <img src="/img/2021/budget-pascal-stack.png">
</picture>

Things are a little more complicated for non-locally used variable; that is using variable declared by the parent scope or using variable as an argument to a var parameter. One big limitation of WebAssembly local variable is that it can't be referenced as a pointer from outside of that function that declare it, so all non-locally used variable must be stored in memory regardless of the data type. For example, consider the following Pascal program.
```pascal
program test;
    var x1, x2: integer;

    procedure outer(var x: integer);
        var y1, y2: integer;

        procedure inner();
        var z: integer;
        begin
            y1 := 1; // use y1 in inner
            // ...
        end;
    begin
        x := 2;
        inner();
        // ...
    end;

begin
    outer(x1); // use x1 as argument to a var parameter
end.
```
Variable x1 and y1 will be stored in memory, while x2, y2 and z will be stored as WebAssembly local variables. The call frame and value stack will look like this when procedure `inner` is called.

<picture>
  <source srcset="/img/2021/budget-pascal-stack-nonlocal-dark.png" media="(prefers-color-scheme:dark)">
  <img src="/img/2021/budget-pascal-stack-nonlocal.png">
</picture>

### Read, ReadLn, and other async operations
This part looked deceptively easy when it's actually not. I wanted to emulate the terminal console on the web page. So naturally I used the [xterm.js](https://xtermjs.org/) library. It's not the easiest thing to use because I needed to manually handle the key and data event from the library, but it's still way faster and easier than reimplementing a terminal UI. The terminal emulator worked!

This was the point where I realized that WebAssembly currently do not support call to asynchronous function or coroutines. If an imported function is an async function or a coroutine, it won't pause execution to wait for the result. There is a way to handle this from inside the WebAssembly code using [Asyncify](https://kripken.github.io/blog/wasm/2019/07/16/asyncify.html), but it involves call stack rewinding and is quite complicated. Instead, I used a combination of [Web Workers](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers) and [Atomics wait and notify](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Atomics) API. Basically, the compiled Pascal program is instantiated and executed inside a Web Worker. When there is an asynchronous call, such as readln, the web worker calls `Atomics.wait()` to pause itself. The main UI thread will call `Atomics.notify()` to the worker thread after a certain event is fired, in this case when a new line is read by the terminal emulator. So problem solved! Well, not quite yet.

It turned out that Atomics wait and notify API need SharedArrayBuffer to work, and SharedArrayBuffer is only enabled[^3] if the page was [cross-origin isolated](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer#security_requirements). This is actually quite simple to achieve by adding extra headers to the top level document http response. Simple, if you have control of the server that serves the page. I didn't have any active VPS at the time and I certainly didn't have access to change response header in Github Page server. While VPS are quite cheap and easy to setup and I might need to use it for other purposes in the future, it's still too much of a hassle and waste to set it up just for serving a static content. Luckily, I found [a blog post](https://dev.to/stefnotch/enabling-coop-coep-without-touching-the-server-2d3n) by stefnotch that exactly solves my problem. The article has more detailed explanation, but it basically works by using a Service Worker to manually add the needed headers to the response.

### Improvements
There are a lot of things that can be improved in my compiler implementation, but here are some of the more important ones.
1. I really should have the parser and the type checker & resolver be seperated into different modules. I made it combined so that it only need two passes (parse + type check then emit binary) instead of three or more (parse, type check, then emit binary). It is faster but in hindsight it's not that big of a difference and it makes the parser code more complex.
2. The runtime library is currently always recompiled everytime a program is compiled. It shouldn't be that hard to pre-compile it and then "copy" it to the compiled program, but I haven't got the time. Also, I should have make the runtime library in higher-level language like C then compile it to WebAssembly, instead of making it manually in WebAssembly. There are some issues with that method (for example, the Pascal runtime will include C runtime and I need to remove it or handle it so it plays nicely), but I think it's way much easier and better to do that if I were to made a serious compiler with a complete standard library.
3. Handling messaging for async operations between the program runner worker thread and the main UI thread is quite a mess and tightly coupled. I haven't got a good idea on how to tidy it up without going too generalized.

### Afterword
All in all I'm satisfied with the result of this project. I found WebAssembly to be an interesting compilation target, although there are definitely some growing pains which should be resolved in the future. I also found this project to be a good reminder of where I am now compared to where I was ten years ago. Hopefully, in another ten years I will see this project the way I see the old hangman game that started this project.

---

#### Footnotes

[^1]: PTI-A class, for those who were pre-2012 ITB students. If I remember correctly, the class was reorganized into PTI-B and DasPro classes for CS & EE students due to a syllabus change in 2012.
[^2]: I'm fully aware that there is a way to [compile Pascal to WebAssembly using FreePascal](https://wiki.freepascal.org/WebAssembly/Compiler) and maybe a lot more other ways, but I also want to make a compiler!
[^3]: This was originally not the case, until Meltdown and Spectre changed everything.
