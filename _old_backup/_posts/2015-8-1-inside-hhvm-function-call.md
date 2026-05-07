---
layout: page
tile: Inside HHVM: Function Call 
time: 2015-08-01 18:02 
---

This series of blogs are designed to explore the inner implementation and desgin of 
[hhvm](hhvm.com), a PHP interpreter developed by Facebook. There are a set of topics
should be covered, including: 

- [Value systems][t1]
- [Interpreter Architecture I: Main Loop][t2]
- Interpreter Architecture II: Stack
- **Interpreter Architecture III: Function Call**
- [Builtin Functions][t3]
- HHVM bytecode
- Jit

HHVM is still in rapid developing, and the version I am working on is 3.6.0.
However, I believe the main design and implementation would remain the same.

### Overview ###

Function is a very important abstraction in any nowadays languages.
How to construct a function and how to call it should be known if
someone really want to understand the design of a language or its
implementation.

For HHVM, there are three phase of a function call:

1. Push function frame
2. Push arguments
3. Call the function

Let's see a concrete example to explore what're these phases do.

### Function Call Workflow ###

In order to fully understand how hhvm works on function calls,
let's see the most naive example as usual. Here is a function-call
example:

    <?php
    
    function foo ($str) {
    	echo "foo is called with $str\n";
    }
    
    foo("hello!");
 
As always, let's use ``hhvm -vEval.DumpHhas=true <example.php>``
command to translate the script into bytecodes. After the translation,
we will see:
 
    .main {
    	FPushFuncD 1 "foo"
    	String "hello!"
    	FPassCE 0
    	FCall 1
    	PopR
    	Int 1
    	RetC
     }
    
    .function [mayusevv] foo($str) {
    	String "foo is called with "
    	CGetL $str
    	Concat
    	String "\n"
    	Concat
    	Print
    	PopC
    	Null
    	RetC
    }

The function ``foo`` is quite clear and easy to understand. 
It is ``.function foo{...}`` in the bytecode. Basically, it
push literal string "foo is called with " into the stack,
get the content in $str to the stack too, and concatenate them
for printing. At last, return Null as result (no one will take
this value actually).

The key point is how can we, the interpreter, find and call
the function "foo". If you see ``.main{...}`` carefully, there
are four basic steps which can be mapped to the phases we talked
in the overview section:

- Push function frame  ->  FPushFuncD
- Push arguments  ->  FPassCE
- Call the function  ->  FCall
- Consume the result  ->  PopR

In the following sections, I will explain them in detail.
Yet, the data structure as well as the mechanism is too both
mass and mess to be clear, so I probably won't show the bloody
details of everythin.

### FPushXXX ###

There are several different FPushXXX bytecode, such as 
FPushFunc, FpushFuncObjMethod, FPushClsMethod and so on.
Ignoring whether they issue a warning or wheter using the stack
of literal string as function name, the FPushXXX bytecode can
be classified into five groups:

- Pure function calls (FPushFunc)
- Object method call  (FPushObjMethod)
- Class method call   (FPushClsMethod)
- Constructor call    (FPushCtor)
- Callable call       (FPushCuf)

The name of the classification is quite self-explaining. In our
most naive example, the program defines a pure function, which
does not belong to any class, and calls it. So we met the 
instruction ``FPushFuncD``.
Here is the implementaion of the instruction ``FPushFuncD``:

    OPTBLD_INLINE void iopFPushFuncD(IOP_ARGS) {
    	pc++;
    	// (1) get the number of arguments
    	auto numArgs = decode_iva(pc);
    	
    	// (2) find the calling function
    	auto id = decode<Id>(pc);
    	const NamedEntityPair nep =
     		vmfp()->m_func->unit()->lookupNamedEntityPairId(id);
     	Func* func = Unit::loadFunc(nep.second, nep.first);
     	
     	// (3) construct the function frame
    	ActRec* ar = fPushFuncImpl(func, numArgs);
    }

The macro is defined as:

	#define IOP_ARGS   PC& pc

(1) **Get the number of arguments**: This line of code fetches the number of
arguments from the bytecode. From the bytecode ``FPushFuncD 1 "foo"``, interpreter
can know how many arguments are there.

(2) **Find the calling function**: This process is pretty similar or basically
the same with the [buitin function][t3] searching. Please refer that for more
information.

(3) **Construct the function frame**: 
This is the key function of the bytecode ``FPushFuncD``. By taking one step further,
the implementation of ``fPushFuncImpl(...)`` is:

    OPTBLD_INLINE ActRec* fPushFuncImpl(const Func* func, int numArgs) {
    	ActRec* ar = vmStack().allocA();
    	ar->m_func = func;  
    	ar->initNumArgs(numArgs);
    	ar->setVarEnv(nullptr);
    	return ar;
    }  

The previous function allocate an ``ActRec`` on the stack and set the attributes
of the structure with function pointer and number of arguments. ``ActRec`` should
be introduced in chapter "Stack" which I haven't finished yet. In short, ``ActRec``
is a representation of function call record with all different kinds of information
related to such function call.

### FPassXXX ###

These instructions are trying to pass the arguments for the function, and basically
what it does is checking if the argument on stack is appropriate. For example,
``FPassCE`` will issue an error if the argument is not satisfied.

### FCall ###

There are series of FCall bytecodes for different purpose. Here I want to
emphasise two kinds of FCall:

- Normal function call (FCall)
- Builtin function call (FCallBuiltin)

Normal function call are calling to the php function which developer written;
while builtin function call are the invokations to the functions php interpreter
or runtime provides. If you want to know more, check [builtin function][t3].

The core functionality of these series of instructions is take the arguments
passing through stack and jump to the entry of the function. This core task has
been implemented in function ``doFCall(...)`` in file [runtime/vm/bytecode.cpp][c1].

Here is a simplified version:

    bool doFCall(ActRec* ar, PC& pc) {
    	prepareFuncEntry(ar, pc, StackArgsState::Untrimmed);
    	vmpc() = pc;
    	return;
    }

The inputs "ar" is the newly created ``ActRec`` by ``FPushFuncD`` and the "pc"
is current program counter. Inside function ``prepareFuncEntry(...)``, the pc will
be rewrote to the function's entry point by the line ``pc = func->getEntry();``.
After that, set the vmpc() to pc and return. The vmpc() is the program counter
for current thread:

	inline const unsigned char*& vmpc() {
		return vmRegs().pc;
	}

### PopR ###

The final stage is consume the result of the function.
For this example, the function ``foo`` don't have any result, so the
bytecode just pop whatever as the result.

If function has a result and caller wants it, like ``$result = foo()``
there would be a snippet of byte code like:

    ...
    FCall 1
    UnboxR
    SetL $result
    PopC
    ...

The return value will be placed on the top of the stack. And the return
variable which is $result in this case will be set to that value, then
pop the result.

### Summary ###

To conclude, in this article, I have tried to give the readers a overview
of how HHVM invoke a function. It includes three stages which are (1) construct
and push the function frame, (2) pass the arguments and (3) jump to the function.

[t1]: {% post_url 2015-7-15-inside-hhvm-value-system %} "value system"
[t2]: {% post_url 2015-7-18-inside-hhvm-main-loop %} "main loop"
[t3]: {% post_url 2015-7-21-inside-hhvm-builtin-function %} "buitin function"
[c1]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/bytecode.cpp "main loop"
