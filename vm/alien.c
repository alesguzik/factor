#include "factor.h"

/* test if alien is no longer valid (it survived an image save/load) */
void primitive_expired(void)
{
	CELL object = dpeek();

	if(type_of(object) == ALIEN_TYPE)
	{
		ALIEN *alien = untag_alien_fast(object);
		drepl(tag_boolean(alien->expired));
	}
	else if(object == F)
		drepl(T);
	else
		drepl(F);
}

/* gets the address of an object representing a C pointer */
void *alien_offset(CELL object)
{
	ALIEN *alien;
	F_ARRAY *array;

	switch(type_of(object))
	{
	case BYTE_ARRAY_TYPE:
		array = untag_byte_array_fast(object);
		return array + 1;
	case ALIEN_TYPE:
		alien = untag_alien_fast(object);
		if(alien->expired)
			general_error(ERROR_EXPIRED,object,F,true);
		return alien_offset(alien->alien) + alien->displacement;
	case F_TYPE:
		return NULL;
	default:
		type_error(ALIEN_TYPE,object);
		return (void*)-1; /* can't happen */
	}
}

/* pop an object representing a C pointer */
void *unbox_alien(void)
{
	return alien_offset(dpop());
}

/* make an alien */
CELL allot_alien(CELL delegate, CELL displacement)
{
	REGISTER_ROOT(delegate);
	ALIEN *alien = allot_object(ALIEN_TYPE,sizeof(ALIEN));
	UNREGISTER_ROOT(delegate);
	alien->alien = delegate;
	alien->displacement = displacement;
	alien->expired = false;
	return tag_object(alien);
}

/* make an alien and push */
void box_alien(CELL ptr)
{
	if(ptr == 0)
		dpush(F);
	else
		dpush(allot_alien(F,ptr));
}

/* make an alien pointing at an offset of another alien */
void primitive_displaced_alien(void)
{
	CELL alien = dpop();
	CELL displacement = unbox_unsigned_cell();
	if(alien == F && displacement == 0)
		dpush(F);
	else
		dpush(allot_alien(alien,displacement));
}

/* address of an object representing a C pointer */
void primitive_alien_address(void)
{
	box_unsigned_cell((CELL)alien_offset(dpop()));
}

/* image loading */
void fixup_alien(ALIEN *d)
{
	d->expired = true;
}

/* pop ( alien n ) from datastack, return alien's address plus n */
INLINE void *alien_pointer(void)
{
	F_FIXNUM offset = unbox_signed_cell();
	return unbox_alien() + offset;
}

/* define words to read/write values at an alien address */
#define DEF_ALIEN_SLOT(name,type,boxer) \
void primitive_alien_##name (void) \
{ \
	box_##boxer (*(type*)alien_pointer()); \
} \
void primitive_set_alien_##name (void) \
{ \
	type* ptr = alien_pointer(); \
	type value = unbox_##boxer(); \
	*ptr = value; \
}

DEF_ALIEN_SLOT(signed_cell,F_FIXNUM,signed_cell)
DEF_ALIEN_SLOT(unsigned_cell,CELL,unsigned_cell)
DEF_ALIEN_SLOT(signed_8,s64,signed_8)
DEF_ALIEN_SLOT(unsigned_8,u64,unsigned_8)
DEF_ALIEN_SLOT(signed_4,s32,signed_4)
DEF_ALIEN_SLOT(unsigned_4,u32,unsigned_4)
DEF_ALIEN_SLOT(signed_2,s16,signed_2)
DEF_ALIEN_SLOT(unsigned_2,u16,unsigned_2)
DEF_ALIEN_SLOT(signed_1,u8,signed_1)
DEF_ALIEN_SLOT(unsigned_1,u8,unsigned_1)
DEF_ALIEN_SLOT(float,float,float)
DEF_ALIEN_SLOT(double,double,double)

/* for FFI calls passing structs by value */
void unbox_value_struct(void *dest, CELL size)
{
	memcpy(dest,unbox_alien(),size);
}

/* for FFI callbacks receiving structs by value */
void box_value_struct(void *src, CELL size)
{
	F_ARRAY *array = allot_byte_array(size);
	memcpy(array + 1,src,size);
	dpush(tag_object(array));
}

/* for FFI calls returning an 8-byte struct. This only
happens on Intel Mac OS X */
void box_value_pair(CELL x, CELL y)
{
	F_ARRAY *array = allot_byte_array(2 * sizeof(CELL));
	put(AREF(array,0),x);
	put(AREF(array,1),y);
	dpush(tag_object(array));
}

void primitive_dlopen(void)
{
	DLL* dll = allot_object(DLL_TYPE,sizeof(DLL));
	dll->path = dpop();
	ffi_dlopen(dll,true);
	dpush(tag_object(dll));
}

void primitive_dlsym(void)
{
	CELL dll = dpop();
	F_STRING *sym = untag_string(dpop());
	DLL *d;
	
	if(dll == F)
		d = NULL;
	else
	{
		d = untag_dll(dll);
		if(d->dll == NULL)
			general_error(ERROR_EXPIRED,dll,F,true);
	}

	box_signed_4((CELL)ffi_dlsym(d,sym,true));
}

void primitive_dlclose(void)
{
	ffi_dlclose(untag_dll(dpop()));
}
