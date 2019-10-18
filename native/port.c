#include "factor.h"

F_PORT* untag_port(CELL tagged)
{
	F_PORT* p;
	type_check(PORT_TYPE,tagged);
	p = (F_PORT*)UNTAG(tagged);
	/* after image load & save, ports are no longer valid */
	if(p->fd == -1)
		general_error(ERROR_EXPIRED,tagged);
	return p;
}

F_PORT* port(PORT_MODE type, CELL fd)
{
	F_PORT* port = allot_object(PORT_TYPE,sizeof(F_PORT));
	port->type = type;
	port->closed = false;
	port->fd = fd;
	port->client_host = F;
	port->client_port = F;
	port->client_socket = F;
	port->line = F;
	port->line_ready = false;
	port->buf_fill = 0;
	port->buf_pos = 0;
	port->io_error = F;

	if(type == PORT_SPECIAL)
		port->buffer = F;
	else
		port->buffer = tag_object(string(BUF_SIZE,'\0'));

#ifndef WIN32
	if(fcntl(port->fd,F_SETFL,O_NONBLOCK,1) == -1)
		io_error(__FUNCTION__);
#endif

	return port;
}

void init_line_buffer(F_PORT* port, F_FIXNUM count)
{
	if(port->line == F)
		port->line = tag_object(sbuf(LINE_SIZE));
}

void fixup_port(F_PORT* port)
{
	port->fd = (F_FIXNUM)INVALID_HANDLE_VALUE;
	data_fixup(&port->buffer);
	data_fixup(&port->line);
	data_fixup(&port->client_host);
	data_fixup(&port->client_port);
	data_fixup(&port->io_error);
}

void collect_port(F_PORT* port)
{
	copy_object(&port->buffer);
	copy_object(&port->line);
	copy_object(&port->client_host);
	copy_object(&port->client_port);
	copy_object(&port->io_error);
}

#ifdef WIN32
CELL make_io_error(const char* func)
{
	F_STRING *function = from_c_string(func);

	return cons(tag_object(function),cons(tag_object(last_error()),F));
}
#else
CELL make_io_error(const char* func)
{
	F_STRING* function = from_c_string(func);
	F_STRING* error = from_c_string(strerror(errno));

	return cons(tag_object(function),cons(tag_object(error),F));
}
#endif

void postpone_io_error(F_PORT* port, const char* func)
{
	port->io_error = make_io_error(func);
}

void io_error(const char* func)
{
	general_error(ERROR_IO,make_io_error(func));
}

void pending_io_error(F_PORT* port)
{
	CELL io_error = port->io_error;
	if(io_error != F)
	{
		port->io_error = F;
		general_error(ERROR_IO,io_error);
	}
	else if(port->closed)
		general_error(ERROR_CLOSED,tag_object(port));
}

void primitive_pending_io_error(void)
{
	pending_io_error(untag_port(dpop()));
}