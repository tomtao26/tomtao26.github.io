---
layout: page
tile: Inside HHVM: Builtin Functions
time: 2015-07-21 21:07
---

This series of blogs are designed to explore the inner implementation and desgin of 
[hhvm](hhvm.com), a PHP interpreter developed by Facebook. There are a set of topics
should be covered, including: 

- [Value systems][t1]
- [Interpreter Architecture I: Main Loop][t2]
- Interpreter Architecture II: Stack
- **Builtin Functions**
- HHVM bytecode
- Jit

HHVM is still in rapid developing, and the version I am working on is 3.6.0.
However, I believe the main design and implementation would remain the same.

### Inside HHVM: Builtin Functions ###

One reason that PHP becomes one of the most popular language in the world is
that it provides a lot of builtin functions which are really convenient
for developers. What I called "builtin functions" here is the function defined
by PHP itself rather than the developers, for example, "file_exists", "fgetcsv"
and so on.

Today our topic is the design and implementation of PHP builtin functions in HHVM.
This can be a very complicated subject. I will only give the big picture
and some important implementation details here.

By thinking how the builtin functions works, the following questions would be
the points interested us:

- What happens when invoking a builtin function?
- Where is the implementation of builtin functions?
- How does the system link the function name and implementation?

Let's see these questions one by one.

### Invoke Builtin Function ###

For one PHP scripts, you can use ``hhvm -vEval.Hhas=true your.php`` to covert
PHP code into bytecodes where "your.php" is the PHP script you want to convert.
So, first, let's see what's the corresponding opcode/bytecode for invoking
builtin functions.

Suppose we have:

	<?php 
	functions_exists("abs");
	?>

After the conversion, we have:

	String "abc"
	True
	FCallBuiltin 2 1 "function_exists"
	UnboxRNop
	PopC
	Int 1
	RetC

As we can see, the opcode **FCallBuiltin** taken three parameter
"2", "1" and "function_exists" would be the key point of invoking
builtin functions. 
The first parameter of **FCallBuiltin** represents the number of arguments
this builtin function could take; The second parameter indicates the actual
number of non default arguments; And the final string is apparently the name of
the builtin function.

The implementation of opcode **FCallBuiltin** is in file 
[runtime/vm/bytecode.cpp][c1]. Here is a simplified version:

	OPTBLD_INLINE void iopFCallBuiltin(IOP_ARGS) {
		pc++;
		// Get three parameters for FCallBuiltin
		auto numArgs = decode_iva(pc);
		auto numNonDefault = decode_iva(pc);
		auto id = decode<Id>(pc);

		// Search for the builtin function
		const NamedEntity* ne = vmfp()->m_func->unit()->lookupNamedEntityId(id);
		Func* func = Unit::lookupFunc(ne);

		// Fetch the arguments
		TypedValue* args = vmStack().indTV(numArgs-1);

		// Invoke the builtin function
		TypedValue ret;
		Native::callFunc<true, false>(func, nullptr, args, ret);
	
		// Clean the invoking
		frame_free_args(args, numNonDefault);
		vmStack().ndiscard(numArgs);
		tvCopy(ret, *vmStack().allocTV());
	}

There are basically five steps to finish calling the builtin function:

(1) **Get three parameters for FCallBuiltin**: the variable "pc" here is 
program counter or instruction pointer which points to current executing instruction.
By given pc to decode_iva/decode, interpreter will know the number of
arguments and non default ones. In our example, numArgs will be 2, and
numNonDefault will be 1.

(2) **Search for the builtin function**: We encounter two new data structure here:
[NamedEntity][c2] and [Unit][c3].
 
> NamedEntity represents a user-defined name that may map to 
> different objects in different requests. 

> Unit is the metadata about a compilation unit which
> Contains the list of PreClasses and global functions.

Basically, what the two line code done here is:
First, query the unit of current function (``vmfp()->m_func``) and
figure out the **NamedEntity** corresponding to the **Id** provided as arguments
of **FCallBuiltin** bytecode. Second, look up the function this **NamedEntity**
represents. In short, we do the process ``id -> NamedEntity -> Func`` and
at last find the function by the id.

(3)**Fetch the arguments**: This line of code is faily simple and self-explaning.
It assigns the "args" pointer to the stack position which is "numArgs" away from
top. Since all the arguments are pushed to stack and there are "numArgs" of them,
the invoking procedure just lets a pointer points to the first argument on stack.

(4)**Invoke the builtin function**: By using ``Native::callFunc()`` function with
the builtin function we found and arguments pointer, the HHVM will invoke the
builtin function pointer feeding the given arguments. The detail of class **Native**
is [here][c4].

(5)**Clean the Invoking**: After the builtin function call, the interpreter
frees the arguments, pops the elements on stack and most importantly copies
the return value to the top of the stack.

### Builtin Function Implementation ###

Usually, the builtin functions are implemented in folder "hphp/runtime/ext".
Let's take the above "function_exists" as an example. It is located in
file "hphp/runtime/ext/ext_std_function.cpp".

	 bool HHVM_FUNCTION(function_exists, const String& function_name,
                         bool autoload /* = true */) {
      return
        function_exists(function_name) ||
        (autoload &&
         AutoloadHandler::s_instance->autoloadFunc(function_name.get()) &&
         function_exists(function_name));
  	}

``HHVM_FUNCTION`` here is a macro which is used to define the pattern of
builtin function's name. The macro's content is the following which is
defined in the file [hphp/runtime/vm/native.h][c5]:

    #define HHVM_FUNCTION(fn, ...) \
            HHVM_FN(fn)(__VA_ARGS__)

And ``HHVM_FN`` is

    #define HHVM_FN(fn) f_ ## fn

To simulate a preprocessor, we can expand the macro and the origin code
would become:

	bool f_function_exists(const String& function_name, bool autoload) {...}

And this function is the real takeing effect function when the bytecode 
``FCallBuiltin 2 1 "function_exists"`` is executing.

### Link Function Name and Implementation ###

The last question would be: how the system links the function name
(i.e. "function_exists") to its real implementation (i.e. ``f_function_exists(...)``)?

First, let me give a brief overview of how it works. During the initialization
of the interpreter, the buitin function implementations will register themselves
to a global table. During the execution, when ``FCallBuiltin`` bytecode is executing,
interpreter will check the global table indexing by the name given by FCallBuiltin,
and get the implementation's function pointer. With such function pointer and the
arguments, the function will be called.

Here is how "function_exists" register itself to the system. The function
``void StandardExtension::initFunction()`` in [hphp/runtime/ext/std/ext_std_function.cpp][c6]
is responds for registering builtin functions. We can see:

	void StandardExtension::initFunction() {
      ...
      HHVM_FE(function_exists); 
      ...

``HHVM_FE`` is still a macro defined [here][c5]:

    #define HHVM_NAMED_FE(fn, fimpl) \
          Native::registerBuiltinFunction(#fn, fimpl)
    #define HHVM_FE(fn) HHVM_NAMED_FE(fn, HHVM_FN(fn))

After unfolding the macro, ``HHVM_FE(function_exists);`` will become:

	Native::registerBuiltinFunction("function_exists", f_function_exists);

It calls the registerBuiltinFunction with the function name
"function_exists" and its real implementation ``f_function_exists(...)``.
Let's see how they are linked together:

	template <class Fun>
	inline void registerBuiltinFunction(const char* name, Fun func) {
	   s_builtinFunctions[makeStaticString(name)] = (BuiltinFunction)func;
	 } 

This is a simplified version, full version is [here][c5].
Apparently, ``s_builtinFunctions`` is the global table whoes index is the
function's name and the value is the function pointer or the builtin function's
implementation.

### Bloody Details ###

There are some bloody details about:

- How the NamedEntity filled with function?
- How to invoke the function?
- How to add a new builtin function?

(1) **How the NamedEntity filled with function**:

_UNKNOWN_

(2) **How to invoke the function**:

- ``template<bool usesDoubles, bool variadic> 
void callFunc(const Func* func, void *ctx,
TypedValue *args, TypedValue& ret)`` in native.cpp
- ``callFuncInt64Impl(...)`` in native-function-caller.h

(3) **How to add a new buitin function**:

_UNKOWN_

### Summary ###

To summary, We have introduced three main topics about buitin function: 
(1) how to invoke the builtin function; (2) where is its implementaion;
and (3) how the name and its implementation linked.



[t1]: {% post_url 2015-7-15-inside-hhvm-value-system %} "value system"
[t2]: {% post_url 2015-7-18-inside-hhvm-main-loop %} "main loop"
[c1]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/bytecode.cpp "main loop"
[c2]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/named-entity.h "namedentity"
[c3]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/unit.h "unit"
[c4]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/native.cpp "runtime/vm/native.cpp"
[c5]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/vm/native.h "hphp/runtime/vm/native.h"
[c6]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/ext/std/ext_std_function.cpp "/runtime/ext/std/ext_std_function.cpp"