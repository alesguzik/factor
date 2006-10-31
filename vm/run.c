#include "factor.h"

INLINE void execute(F_WORD* word)
{
	((XT)(word->xt))(word);
}

INLINE void push_callframe(void)
{
	cs += CELLS * 3;
	put(cs - CELLS * 2,callframe);
	put(cs - CELLS,callframe_scan);
	put(cs,callframe_end);
}

INLINE void set_callframe(CELL quot)
{
	F_ARRAY *untagged = (F_ARRAY*)UNTAG(quot);
	type_check(QUOTATION_TYPE,quot);
	callframe = quot;
	callframe_scan = AREF(untagged,0);
	callframe_end = AREF(untagged,array_capacity(untagged));
}

void call(CELL quot)
{
	if(quot == F)
		return;

	/* tail call optimization */
	if(callframe_scan < callframe_end)
		push_callframe();

	set_callframe(quot);
}

/* Called from interpreter() */
void handle_error(void)
{
	if(throwing)
	{
		if(thrown_keep_stacks)
		{
			ds = thrown_ds;
			rs = thrown_rs;
		}
		else
			fix_stacks();

		dpush(thrown_error);
		/* Notify any 'catch' blocks */
		push_callframe();
		set_callframe(userenv[BREAK_ENV]);
		throwing = false;
	}
}

void interpreter_loop(void)
{
	CELL next;

	for(;;)
	{
		if(callframe_scan == callframe_end)
		{
			if(cs_bot - cs == CELLS)
				return;

			callframe_end = get(cs);
			callframe_scan = get(cs - CELLS);
			callframe = get(cs - CELLS * 2);
			cs -= CELLS * 3;
			continue;
		}

		next = get(callframe_scan);
		callframe_scan += CELLS;

		switch(TAG(next))
		{
		case WORD_TYPE:
			execute(untag_word_fast(next));
			break;
		case WRAPPER_TYPE:
			dpush(untag_wrapper_fast(next)->object);
			break;
		default:
			dpush(next);
			break;
		}
	}
}

void interpreter(void)
{
	SETJMP(stack_chain->toplevel);
	handle_error();
	interpreter_loop();
}

/* Called by compiled callbacks after nest_stacks() and boxing registers */
void run_callback(CELL quot)
{
	call(quot);
	run();
}

/* XT of deferred words */
void undefined(F_WORD* word)
{
	general_error(ERROR_UNDEFINED_WORD,tag_word(word),F,true);
}

/* XT of compound definitions */
void docol(F_WORD* word)
{
	call(word->def);
}

/* pushes word parameter */
void dosym(F_WORD* word)
{
	dpush(word->def);
}

void primitive_execute(void)
{
	execute(untag_word(dpop()));
}

void primitive_call(void)
{
	call(dpop());
}

void primitive_ifte(void)
{
	ds -= CELLS * 3;
	call(get(ds + CELLS) == F ? get(ds + CELLS * 3) : get(ds + CELLS * 2));
}

void primitive_dispatch(void)
{
	F_ARRAY *a = untag_array_fast(dpop());
	F_FIXNUM n = untag_fixnum_fast(dpop());
	call(get(AREF(a,n)));
}

void primitive_getenv(void)
{
	F_FIXNUM e = untag_fixnum_fast(dpeek());
	drepl(userenv[e]);
}

void primitive_setenv(void)
{
	F_FIXNUM e = untag_fixnum_fast(dpop());
	CELL value = dpop();
	userenv[e] = value;
}

void primitive_exit(void)
{
	exit(unbox_signed_cell());
}

void primitive_os_env(void)
{
	char *name = unbox_char_string();
	char *value = getenv(name);
	if(value == NULL)
		dpush(F);
	else
		box_char_string(value);
}

void primitive_eq(void)
{
	CELL lhs = dpop();
	CELL rhs = dpeek();
	drepl((lhs == rhs) ? T : F);
}

void primitive_millis(void)
{
	box_unsigned_8(current_millis());
}

void primitive_type(void)
{
	drepl(tag_fixnum(type_of(dpeek())));
}

void primitive_tag(void)
{
	drepl(tag_fixnum(TAG(dpeek())));
}

void primitive_slot(void)
{
	F_FIXNUM slot = untag_fixnum_fast(dpop());
	CELL obj = UNTAG(dpop());
	dpush(get(SLOT(obj,slot)));
}

void primitive_set_slot(void)
{
	F_FIXNUM slot = untag_fixnum_fast(dpop());
	CELL obj = UNTAG(dpop());
	CELL value = dpop();
	put(SLOT(obj,slot),value);
	write_barrier(obj);
}

void primitive_clone(void)
{
	CELL size = object_size(dpeek());
	void *new_obj = allot(size);
	CELL tag = TAG(dpeek());
	memcpy(new_obj,(void*)UNTAG(dpeek()),size);
	drepl(RETAG(new_obj,tag));
}

void fatal_error(char* msg, CELL tagged)
{
	fprintf(stderr,"Fatal error: %s %lx\n",msg,tagged);
	exit(1);
}

void critical_error(char* msg, CELL tagged)
{
	fprintf(stderr,"Critical error: %s %lx\n",msg,tagged);
	factorbug();
}

void early_error(CELL error)
{
	if(userenv[BREAK_ENV] == F)
	{
		/* Crash at startup */
		fprintf(stderr,"Error during startup: ");
		print_obj(error);
		fprintf(stderr,"\n");
		factorbug();
	}
}

void throw_error(CELL error, bool keep_stacks)
{
	early_error(error);

	throwing = true;
	thrown_error = error;
	thrown_keep_stacks = keep_stacks;
	thrown_ds = ds;
	thrown_rs = rs;

	/* Return to interpreter() function */
	LONGJMP(stack_chain->toplevel,1);
}

void primitive_throw(void)
{
	throw_error(dpop(),true);
}

void primitive_die(void)
{
	factorbug();
}

void general_error(F_ERRORTYPE error, CELL arg1, CELL arg2, bool keep_stacks)
{
	throw_error(allot_array_4(userenv[ERROR_ENV],
		tag_fixnum(error),arg1,arg2),keep_stacks);
}

void memory_protection_error(CELL addr, int signal)
{
	if(in_page(addr, ds_bot, 0, -1))
		general_error(ERROR_DS_UNDERFLOW,F,F,false);
	else if(in_page(addr, ds_bot, ds_size, 0))
		general_error(ERROR_DS_OVERFLOW,F,F,false);
	else if(in_page(addr, rs_bot, 0, -1))
		general_error(ERROR_RS_UNDERFLOW,F,F,false);
	else if(in_page(addr, rs_bot, rs_size, 0))
		general_error(ERROR_RS_OVERFLOW,F,F,false);
	else if(in_page(addr, cs_bot, 0, -1))
		general_error(ERROR_CS_UNDERFLOW,F,F,false);
	else if(in_page(addr, cs_bot, cs_size, 0))
		general_error(ERROR_CS_OVERFLOW,F,F,false);
	else if(in_page(addr, nursery.limit, 0, 0))
		critical_error("Out of memory",0);
		signal_error(signal);
}

/* It is not safe to access 'ds' from a signal handler, so we just not
touch it */
void signal_error(int signal)
{
	general_error(ERROR_SIGNAL,tag_fixnum(signal),F,false);
}

void type_error(CELL type, CELL tagged)
{
	general_error(ERROR_TYPE,tag_fixnum(type),tagged,true);
}
