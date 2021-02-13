---
layout: page
tile: Inside HHVM: Value System 
time: 2015-07-18 14:40
---

This series of blogs are designed to explore the inner implementation and desgin of 
[hhvm](hhvm.com), a PHP interpreter developed by Facebook. There are a set of topics
should be covered, including: 

- [Value systems][t1]
- **Interpreter Architecture I: Main Loop**
- HHVM bytecode
- Jit

HHVM is still in rapid developing, and the version I am working on is 3.6.0.
However, I believe the main design and implementation would remain the same.

### Inside HHVM: Main Loop ###

>  Program = Data Structures + Alogirthms

In [HHVM value system][t1], we know what data structures are used to store different types
of value. In this charpter, "algorithm" of the interpreter become our topic.
In short, HHVM simulates what CPU does. It fetches the current instruction, executes it, updates
the states and fetches the next instruction, so on and so forth. I personally call this
fetch-execute-fetch procedure the "**Main Loop**".

### HipHop Bytecode ###

Like CPU, HHVM has its own ISA which called HipHop Bytecode.
When HHVM tries to execute a PHP script, it first translates the PHP source code to
an intermediate representation which called HHBC (HipHop bytecode), then execute the bytecode
line by line. The HHBC is very much like Java bytecode. You can check the detailed 
design and its semantics [here][c1].

> HipHop bytecode (HHBC) v1 is intended to serve as the conceptual basis for
encoding the semantic meaning of HipHop source code into a format that is
appropriate for consumption by interpreters and just-in-time compilers. By
using simpler constructs to encode more complex expressions and statements,
HHBC makes it straightforward for an interpreter or a compiler to determine
the order of execution for a program.

Let's take the naivest "hello world" program as an example. Suppose we have a hello-world
PHP program:

	<?php
	  $a = "hello world";
	  echo $a;
	?>

We can imagine this snippet of PHP code will be "compiled" to a series of HipHop bytecode:

	String "hello world"
	SetL $a
	PopC
	CGetL $a
	Print
	PopC
	Int 1
	RetC
	
Each line of bytecode will be one instruction fetched and executed by HHVM interpreter.

### Abstract Architecture of Interpreter ###

The abstract architecture of interpreter is fairly simple.
It can be a big loop like:

	for(;;) {
		ins = fetch(); // fetch the new instrucction
		
		switch(ins) {  // jump to the right instruction
			case String: ...
			case SetL: ...
			case PopC: ...
			...
		}
	}

The logic of "Main Loop" is just like described above.
Each time the interpreter fetches a instruction, it check what
the instruction is and jump to the corresponding instruction function.
After execution, it will do the fetching again until meet the EXIT instruction
or reach the end of the program. In the following paragraphs, I will use
instruction and bytecode interchangeably.

### HHVM Main Loop ###

Sharing the same logic with our abstract architecure discribed in last section,
HHVM uses a different way to implement fetch-execute-fetch procedure. It adds
the "fetch and switch" operation to the end of each instruction function.
Instruction function is the function which implements what the bytecode,
say SetL/Popc, should do. 

The pesudocode of the design is like: 

	jumpTab[] = {
		iopString,
		iopSetL,
		iopPopC,
	};
	
	void fetchAndJump() {
		ins = fetch();
		jumpTab[ins]();
	}
	
	void iopString() {... fetchAndJump();}
	void iopSetL()   {... fetchAndJump();}
	void iopPopC()   {... fetchAndJump();}

When the interpreter finishes one instruction execution, say "SetL", which should
be running "iopSetL()", it will called "fetchAndJump()". And the "fetchAndJump()"
will continue the program by jummping to the next instruction function.

In order to implement such design, we need to three components:

- Jumping table
- Fetch and jump function
- Instruction functions

### Jumping Table ###

In order to implement the design, HHVM first define a function table which
contains all the instruction functions HHVM supports. HHVM uses the macro to
generate such table in [runtime/vm/bytecode.cpp][c2]:

	static const void *optabDirect[] = {
		#define O(name, imm, push, pop, flags) \
		&&Label##name,
		OPCODES
		#undef O
	};

It will be little tricky to understand the code by first sight.
The "OPCODES" above is a macro declared in [runtime/vm/hhbc.h][c3]:

	//  name             immediates        inputs           outputs     flags
 	#define OPCODES \
       ...
       O(PopC,            NA,               ONE(CV),         NOV,        NF) \
       ...
       O(String,          ONE(SA),          NOV,             ONE(CV),    NF) \
       ...
       O(SetL,            ONE(LA),          ONE(CV),         ONE(CV),    NF) \
       ...

As you can see, after the preprocessor, 
the the "opttabDirect" will be expanded as:

	static const void *optabDirect[] = {
		...
		&&LabelPopC,
		...
		&&LabelString,
		...
		&&LabelSetL,
		...

With this table, HHVM can use ``goto *optab[uint8_t(op)]`` ("op" is the instruction
number) jumping to the instruction function very efficiently. 

### Fetch and Jump Function ###

The "fetch and jump" function is also a macro in HHVM called "DISPATCH". This
is the simplified version. If you want to see the original one please check
[runtime/vm/bytecode.cpp][c2].

	#define DISPATCH() do {                      \
		Op op = *reinterpret_cast<const Op*>(pc); \
		goto *optab[uint8_t(op)];                 \
	} while(0)

### Instruction Functions ###

The real implementation of each instruction is defined in the 
corresponding function named "iop<bytecode-name>". For example,
for instruction/bytecode "PopC", the corresponding function is
"iopPopC".

However, if you read the section [Jumping Table](#jumping-table) really carefully,
you will find that the jumping table contains a series of labels rather
than function pointers. HHVM needs somehow adding the labels to the
corresponding instruction functions. Here is the snippet of code
to do such work. Still they are macro. There are several good reasons
to use "lable + macro" rather than "function pointer" table.

	#define O(name, imm, push, pop, flags)  \
		Label##name: {                       \
			iop##name(pc);                    \
			vmpc() = pc;                      \
			DISPATCH();                       \
		}
		OPCODES

As usual, this is a simplified version, you can check the full version
[here][c2]. To recall, "OPCODES" is a macro we mentioned in section 
[Jumping Table](#jumping-table); macro "DISPATCH" is a macro we mentioned 
in section [Fetch and Jump Function](#fetch-and-jump-function).
This macro will build a series of labels each of which will (1) call
instruction function (2) call fetch-and-jump function.

### Summary ###

To conclude, we have discussed the main logic of the interpreter and given a
detail analysis on the implementaion of HHVM's "Main Loop".

[t1]: {% post_url 2015-7-15-inside-hhvm-value-system %} "value system"
[c1]: https://github.com/facebook/hhvm/blob/master/hphp/doc/bytecode.specification "bytecode spec"
[c2]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/bytecode.cpp "main loop"
[c3]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/hhbc.h "hhbc"
