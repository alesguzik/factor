#include "master.hpp"

CELL string_nth(F_STRING* string, CELL index)
{
	/* If high bit is set, the most significant 16 bits of the char
	come from the aux vector. The least significant bit of the
	corresponding aux vector entry is negated, so that we can
	XOR the two components together and get the original code point
	back. */
	CELL ch = bget(SREF(string,index));
	if((ch & 0x80) == 0)
		return ch;
	else
	{
		F_BYTE_ARRAY *aux = untag_byte_array_fast(string->aux);
		return (cget(BREF(aux,index * sizeof(u16))) << 7) ^ ch;
	}
}

void set_string_nth_fast(F_STRING *string, CELL index, CELL ch)
{
	bput(SREF(string,index),ch);
}

void set_string_nth_slow(F_STRING *string_, CELL index, CELL ch)
{
	gc_root<F_STRING> string(string_);

	F_BYTE_ARRAY *aux;

	bput(SREF(string.untagged(),index),(ch & 0x7f) | 0x80);

	if(string->aux == F)
	{
		/* We don't need to pre-initialize the
		byte array with any data, since we
		only ever read from the aux vector
		if the most significant bit of a
		character is set. Initially all of
		the bits are clear. */
		aux = allot_array_internal<F_BYTE_ARRAY>(
			untag_fixnum_fast(string->length)
			* sizeof(u16));

		write_barrier(string.value());
		string->aux = tag_object(aux);
	}
	else
		aux = untag_byte_array_fast(string->aux);

	cput(BREF(aux,index * sizeof(u16)),(ch >> 7) ^ 1);
}

/* allocates memory */
void set_string_nth(F_STRING* string, CELL index, CELL ch)
{
	if(ch <= 0x7f)
		set_string_nth_fast(string,index,ch);
	else
		set_string_nth_slow(string,index,ch);
}

/* Allocates memory */
F_STRING *allot_string_internal(CELL capacity)
{
	F_STRING *string = allot<F_STRING>(string_size(capacity));

	string->length = tag_fixnum(capacity);
	string->hashcode = F;
	string->aux = F;

	return string;
}

/* Allocates memory */
void fill_string(F_STRING *string_, CELL start, CELL capacity, CELL fill)
{
	gc_root<F_STRING> string(string_);

	if(fill <= 0x7f)
		memset((void *)SREF(string.untagged(),start),fill,capacity - start);
	else
	{
		CELL i;

		for(i = start; i < capacity; i++)
			set_string_nth(string.untagged(),i,fill);
	}
}

/* Allocates memory */
F_STRING *allot_string(CELL capacity, CELL fill)
{
	gc_root<F_STRING> string(allot_string_internal(capacity));
	fill_string(string.untagged(),0,capacity,fill);
	return string.untagged();
}

void primitive_string(void)
{
	CELL initial = to_cell(dpop());
	CELL length = unbox_array_size();
	dpush(tag_object(allot_string(length,initial)));
}

static bool reallot_string_in_place_p(F_STRING *string, CELL capacity)
{
	return in_zone(&nursery,(CELL)string) && capacity <= string_capacity(string);
}

F_STRING* reallot_string(F_STRING *string_, CELL capacity)
{
	gc_root<F_STRING> string(string_);

	if(reallot_string_in_place_p(string.untagged(),capacity))
	{
		string->length = tag_fixnum(capacity);

		if(string->aux != F)
		{
			F_BYTE_ARRAY *aux = untag_byte_array_fast(string->aux);
			aux->capacity = tag_fixnum(capacity * 2);
		}

		return string.untagged();
	}
	else
	{
		CELL to_copy = string_capacity(string.untagged());
		if(capacity < to_copy)
			to_copy = capacity;

		gc_root<F_STRING> new_string(allot_string_internal(capacity));

		memcpy(new_string.untagged() + 1,string.untagged() + 1,to_copy);

		if(string->aux != F)
		{
			F_BYTE_ARRAY *new_aux = allot_byte_array(capacity * sizeof(u16));

			write_barrier(new_string.value());
			new_string->aux = tag_object(new_aux);

			F_BYTE_ARRAY *aux = untag_byte_array_fast(string->aux);
			memcpy(new_aux + 1,aux + 1,to_copy * sizeof(u16));
		}

		fill_string(new_string.untagged(),to_copy,capacity,'\0');
		return new_string.untagged();
	}
}

void primitive_resize_string(void)
{
	F_STRING* string = untag_string(dpop());
	CELL capacity = unbox_array_size();
	dpush(tag_object(reallot_string(string,capacity)));
}

/* Some ugly macros to prevent a 2x code duplication */

#define MEMORY_TO_STRING(type,utype) \
	F_STRING *memory_to_##type##_string(const type *string, CELL length) \
	{ \
		REGISTER_C_STRING(string); \
		gc_root<F_STRING> s(allot_string_internal(length)); \
		UNREGISTER_C_STRING(type,string); \
		CELL i; \
		for(i = 0; i < length; i++) \
		{ \
			set_string_nth(s.untagged(),i,(utype)*string);	\
			string++; \
		} \
		return s.untagged(); \
	} \
	F_STRING *from_##type##_string(const type *str) \
	{ \
		CELL length = 0; \
		const type *scan = str; \
		while(*scan++) length++; \
		return memory_to_##type##_string(str,length); \
	} \
	void box_##type##_string(const type *str) \
	{ \
		dpush(str ? tag_object(from_##type##_string(str)) : F); \
	}

MEMORY_TO_STRING(char,u8)
MEMORY_TO_STRING(u16,u16)
MEMORY_TO_STRING(u32,u32)

bool check_string(F_STRING *s, CELL max)
{
	CELL capacity = string_capacity(s);
	CELL i;
	for(i = 0; i < capacity; i++)
	{
		CELL ch = string_nth(s,i);
		if(ch == 0 || ch >= ((CELL)1 << (max * 8)))
			return false;
	}
	return true;
}

F_BYTE_ARRAY *allot_c_string(CELL capacity, CELL size)
{
	return allot_byte_array((capacity + 1) * size);
}

#define STRING_TO_MEMORY(type) \
	void type##_string_to_memory(F_STRING *s, type *string) \
	{ \
		CELL i; \
		CELL capacity = string_capacity(s); \
		for(i = 0; i < capacity; i++) \
			string[i] = string_nth(s,i); \
	} \
	void primitive_##type##_string_to_memory(void) \
	{ \
		type *address = (type *)unbox_alien();	\
		F_STRING *str = untag_string(dpop()); \
		type##_string_to_memory(str,address); \
	} \
	F_BYTE_ARRAY *string_to_##type##_alien(F_STRING *s_, bool check) \
	{ \
		gc_root<F_STRING> s(s_); \
		CELL capacity = string_capacity(s.untagged());	\
		F_BYTE_ARRAY *_c_str; \
		if(check && !check_string(s.untagged(),sizeof(type)))	\
			general_error(ERROR_C_STRING,s.value(),F,NULL);	\
		_c_str = allot_c_string(capacity,sizeof(type)); \
		type *c_str = (type*)(_c_str + 1); \
		type##_string_to_memory(s.untagged(),c_str);	\
		c_str[capacity] = 0; \
		return _c_str; \
	} \
	type *to_##type##_string(F_STRING *s, bool check) \
	{ \
		return (type*)(string_to_##type##_alien(s,check) + 1); \
	} \
	type *unbox_##type##_string(void) \
	{ \
		return to_##type##_string(untag_string(dpop()),true); \
	}

STRING_TO_MEMORY(char);
STRING_TO_MEMORY(u16);

void primitive_string_nth(void)
{
	F_STRING *string = untag_string_fast(dpop());
	CELL index = untag_fixnum_fast(dpop());
	dpush(tag_fixnum(string_nth(string,index)));
}

void primitive_set_string_nth(void)
{
	F_STRING *string = untag_string_fast(dpop());
	CELL index = untag_fixnum_fast(dpop());
	CELL value = untag_fixnum_fast(dpop());
	set_string_nth(string,index,value);
}

void primitive_set_string_nth_fast(void)
{
	F_STRING *string = untag_string_fast(dpop());
	CELL index = untag_fixnum_fast(dpop());
	CELL value = untag_fixnum_fast(dpop());
	set_string_nth_fast(string,index,value);
}

void primitive_set_string_nth_slow(void)
{
	F_STRING *string = untag_string_fast(dpop());
	CELL index = untag_fixnum_fast(dpop());
	CELL value = untag_fixnum_fast(dpop());
	set_string_nth_slow(string,index,value);
}
