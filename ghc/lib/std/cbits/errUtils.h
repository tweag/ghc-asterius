/* 
 * (c) The University of Glasgow, 2000-2001
 *
 * GHC Error Number Conversion - prototypes.
 */
#ifndef __ERRUTILS_H__
#define __ERRUTILS_H__

#include "HsStd.h"

#define ErrCodeProto(x) extern HsInt prel_error_##x()

ErrCodeProto(E2BIG);
ErrCodeProto(EACCES);
ErrCodeProto(EADDRINUSE);
ErrCodeProto(EADDRNOTAVAIL);
ErrCodeProto(EADV);
ErrCodeProto(EAFNOSUPPORT);
ErrCodeProto(EAGAIN);
ErrCodeProto(EALREADY);
ErrCodeProto(EBADF);
ErrCodeProto(EBADMSG);
ErrCodeProto(EBADRPC);
ErrCodeProto(EBUSY);
ErrCodeProto(ECHILD);
ErrCodeProto(ECOMM);
ErrCodeProto(ECONNABORTED);
ErrCodeProto(ECONNREFUSED);
ErrCodeProto(ECONNRESET);
ErrCodeProto(EDEADLK);
ErrCodeProto(EDESTADDRREQ);
ErrCodeProto(EDIRTY);
ErrCodeProto(EDOM);
ErrCodeProto(EDQUOT);
ErrCodeProto(EEXIST);
ErrCodeProto(EFAULT);
ErrCodeProto(EFBIG);
ErrCodeProto(EFTYPE);
ErrCodeProto(EHOSTDOWN);
ErrCodeProto(EHOSTUNREACH);
ErrCodeProto(EIDRM);
ErrCodeProto(EILSEQ);
ErrCodeProto(EINPROGRESS);
ErrCodeProto(EINTR);
ErrCodeProto(EINVAL);
ErrCodeProto(EIO);
ErrCodeProto(EISCONN);
ErrCodeProto(EISDIR);
ErrCodeProto(ELOOP);
ErrCodeProto(EMFILE);
ErrCodeProto(EMLINK);
ErrCodeProto(EMSGSIZE);
ErrCodeProto(EMULTIHOP);
ErrCodeProto(ENAMETOOLONG);
ErrCodeProto(ENETDOWN);
ErrCodeProto(ENETRESET);
ErrCodeProto(ENETUNREACH);
ErrCodeProto(ENFILE);
ErrCodeProto(ENOBUFS);
ErrCodeProto(ENODATA);
ErrCodeProto(ENODEV);
ErrCodeProto(ENOENT);
ErrCodeProto(ENOEXEC);
ErrCodeProto(ENOLCK);
ErrCodeProto(ENOLINK);
ErrCodeProto(ENOMEM);
ErrCodeProto(ENOMSG);
ErrCodeProto(ENONET);
ErrCodeProto(ENOPROTOOPT);
ErrCodeProto(ENOSPC);
ErrCodeProto(ENOSR);
ErrCodeProto(ENOSTR);
ErrCodeProto(ENOSYS);
ErrCodeProto(ENOTBLK);
ErrCodeProto(ENOTCONN);
ErrCodeProto(ENOTDIR);
ErrCodeProto(ENOTEMPTY);
ErrCodeProto(ENOTSOCK);
ErrCodeProto(ENOTTY);
ErrCodeProto(ENXIO);
ErrCodeProto(EOPNOTSUPP);
ErrCodeProto(EPERM);
ErrCodeProto(EPFNOSUPPORT);
ErrCodeProto(EPIPE);
ErrCodeProto(EPROCLIM);
ErrCodeProto(EPROCUNAVAIL);
ErrCodeProto(EPROGMISMATCH);
ErrCodeProto(EPROGUNAVAIL);
ErrCodeProto(EPROTO);
ErrCodeProto(EPROTONOSUPPORT);
ErrCodeProto(EPROTOTYPE);
ErrCodeProto(ERANGE);
ErrCodeProto(EREMCHG);
ErrCodeProto(EREMOTE);
ErrCodeProto(EROFS);
ErrCodeProto(ERPCMISMATCH);
ErrCodeProto(ERREMOTE);
ErrCodeProto(ESHUTDOWN);
ErrCodeProto(ESOCKTNOSUPPORT);
ErrCodeProto(ESPIPE);
ErrCodeProto(ESRCH);
ErrCodeProto(ESRMNT);
ErrCodeProto(ESTALE);
ErrCodeProto(ETIME);
ErrCodeProto(ETIMEDOUT);
ErrCodeProto(ETOOMANYREFS);
ErrCodeProto(ETXTBSY);
ErrCodeProto(EUSERS);
ErrCodeProto(EWOULDBLOCK);
ErrCodeProto(EXDEV);

#endif /* __ERRUTILS_H__ */
