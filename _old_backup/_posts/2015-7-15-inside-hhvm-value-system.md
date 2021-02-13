---
layout: page
tile: Inside HHVM: Value System 
time: 2015-07-15 10:41
---

This series of blogs are designed to explore the inner implementation and desgin of 
[hhvm](hhvm.com), a PHP interpreter developed by Facebook. There are a set of topics
should be covered, including: 

- **Value systems**
- Interpreter Architecture
- HHVM bytecode
- Jit

HHVM is still in rapid developing, and the version I am working on is 3.6.0.
However, I believe
the main design and implementation would remain the same.

### Inside HHVM: Value System ###

>  Program = Data Structures + Alogirthms

In order to understand how the HHVM works, we have to first understand how the data
or variable are stored inside the interpreter.
As we all know, PHP has a series of value types, such as integer, float, string and so on.
What's their data structures and how HHVM organizes them will be our first topic.


### PHP Basic Types ###

[PHP types][1] include four
scalar types:

- boolean
- integer
- float
- string

Two compound types:

- array
- object

Two special types

- resource
- NULL

Basically, the types are kind of self-explaining. If you want to know more, please
check [PHP types][1] or other references.

### HHVM Value Data Structures ###

PHP types are defined in header file typed-value.h
([hphp/runtime/base/typed-value.h][2]).
For one value the base struct is TypedValue whose definition is:

**TypedValue** ([hphp/runtime/base/typed-value.h][2])

	struct TypedValue {
		Value m_data;
		DataType m_type;
		AuxUnion m_aux;
	};

> A TypedValue is a descriminated PHP Value. m_tag describes the contents
of m_data.  m_aux must only be read or written
in specialized contexts.

The definition is clear. m_data is where real data have been stored; m_type tells
HHVM how to interpret the m_data. m_aux is for auxiliary usage which I probably will
not describe here. Following the m_type, let us first see what "DataType" structure looks like.

**DataType** ([hphp/runtime/base/datatype.h][3])

	enum DataType : int8_t {
		// Values below zero are not PHP values, but runtime-internal.
		KindOfClass         = -13,

		// Any code that static_asserts about the value of KindOfNull may also depend
		// on there not being any values between KindOfUninit and KindOfNull.

		//      uncounted init bit
		//      |string bit
		//      ||
		KindOfUninit        = 0x00,  //  00000000
		KindOfNull          = 0x08,  //  00001000
		KindOfBoolean       = 0x09,  //  00001001
		KindOfInt64         = 0x0a,  //  00001010
		KindOfDouble        = 0x0b,  //  00001011
		KindOfStaticString  = 0x0c,  //  00001100
		KindOfString        = 0x14,  //  00010100
		KindOfArray         = 0x20,  //  00100000
		KindOfObject        = 0x30,  //  00110000
		KindOfResource      = 0x40,  //  01000000
		KindOfRef           = 0x50,  //  01010000
	};

>  DataType is the type tag for a TypedValue (see typed-value.h).
>
>  Beware if you change the order, as we may have a few type checks in the code
>  that depend on the order.  Also beware of adding to the number of bits
>  needed to represent this.  (Known dependency in unwind-x64.h.)

The definition of DataType declares all the types (eight of them) we know
from the previous PHP type introductions: **bool/int/double/string/array/object/resource/Null**.
And more, we can see **class** which has already mentioned in code commons as runtime-internal type;
As well as, **uninit/staticString/Ref**, which we will see later when we discuss the bytecode of HHVM
and the internal logic of HHVM.

After knowing what the type of this value, the next step is to know what is the value.

**Value** ([hphp/runtime/base/typed-value.h][2])

	union Value {
		int64_t       num;    // KindOfInt64, KindOfBool (must be zero-extended)
		double        dbl;    // KindOfDouble
		StringData*   pstr;   // KindOfString, KindOfStaticString
		ArrayData*    parr;   // KindOfArray
		ObjectData*   pobj;   // KindOfObject
		ResourceData* pres;   // KindOfResource
		Class*        pcls;   // only in vm stack, no type tag.
		RefData*      pref;   // KindOfRef
	};


> This is the payload of a PHP value. This union may only be used in
contexts that have a discriminator, e.g. in TypedValue, or
when the type is known beforehand.

The description above is pretty clear for the union Value. Based on the type of the value, this structure/union
can be translated to different types. The **int** and **double** are fundamental type in C++. While others
are newly defined structures, such as **string** will be a pointer to a structure called StringData.

The newly defined data structures are:

| PHP type  |  HHVM structure | defined file |
|-----------|---------------|------------|
|string     |StringData     |[runtime/base/string-data.h][4]|
|array      |ArrayData      |[runtime/base/array-data.h][5]|
|object     |ObjectData     |[runtime/base/object-data.h][6]|
|resource   |ResourceData   |[runtime/base/resource-data.h][7]|

### Summary ###

To conclude, we review the type system in PHP which has eight different types and 
explore their detailed implementation inside HHVM interpreter. To be more specific,
one value of any type will be a "TypedValue", within which are field "m_type" indicating the type
of such value and field "m_data" containing the real data payload. Except for fundamental
types like int/double/boolean, other types have HHVM's own implementation in different files 
(see table for more information).


[1]: http://php.net/manual/en/language.types.intro.php  "php type"
[2]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/base/typed-value.h "type value"
[3]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/base/datatype.h    "data type"
[4]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/base/string-data.h  "string data"
[5]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/base/array-data.h  "array data"
[6]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/base/object-data.h  "object data"
[7]: https://github.com/facebook/hhvm/blob/master/hphp/runtime/base/resource-data.h "res data"
