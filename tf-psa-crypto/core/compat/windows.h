#ifndef TF_PSA_CRYPTO_COMPAT_WINDOWS_H
#define TF_PSA_CRYPTO_COMPAT_WINDOWS_H

// Windows API 基本类型和函数定义
// 用于 Zig C 编译器在 Windows 上编译

#ifndef WINAPI
#define WINAPI
#endif

// 基本类型
typedef void VOID;
typedef int BOOL;
typedef unsigned long DWORD;
typedef unsigned int UINT;
typedef unsigned long ULONG;
typedef int INT;
typedef long LONG;
typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef void *HANDLE;
typedef const void *LPCVOID;
typedef void *LPVOID;
typedef void *PVOID;
typedef char *LPSTR;
typedef const char *LPCSTR;
typedef DWORD *LPDWORD;

// 文件操作相关
typedef unsigned long DWORD_PTR;
typedef long LONG_PTR;
typedef unsigned long ULONG_PTR;

// 重叠结构体简化版
typedef struct {
    DWORD Internal;
    DWORD InternalHigh;
    union {
        struct {
            DWORD Offset;
            DWORD OffsetHigh;
        };
        PVOID Pointer;
    };
} OVERLAPPED;
typedef OVERLAPPED *LPOVERLAPPED;

// 移动文件标志
#define MOVEFILE_REPLACE_EXISTING 0x00000001
#define MOVEFILE_COPY_ALLOWED 0x00000002
#define MOVEFILE_DELAY_UNTIL_REBOOT 0x00000004

// 文件访问标志
#define GENERIC_READ    (0x80000000)
#define GENERIC_WRITE   (0x40000000)
#define GENERIC_EXECUTE (0x20000000)
#define GENERIC_ALL     (0x10000000)

// 文件共享模式
#define FILE_SHARE_READ   0x00000001
#define FILE_SHARE_WRITE  0x00000002
#define FILE_SHARE_DELETE 0x00000004

// 文件创建标志
#define CREATE_NEW 1
#define CREATE_ALWAYS 2
#define OPEN_EXISTING 3
#define OPEN_ALWAYS 4
#define TRUNCATE_EXISTING 5

// 文件属性
#define FILE_ATTRIBUTE_NORMAL 0x00000080
#define FILE_ATTRIBUTE_DIRECTORY 0x00000010

// 错误代码
#define INVALID_HANDLE_VALUE ((HANDLE)-1)

// 文件操作函数声明
HANDLE CreateFileA(
    const char *lpFileName,
    DWORD dwDesiredAccess,
    DWORD dwShareMode,
    LPVOID lpSecurityAttributes,
    DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes,
    HANDLE hTemplateFile
);

BOOL ReadFile(
    HANDLE hFile,
    LPVOID lpBuffer,
    DWORD nNumberOfBytesToRead,
    LPDWORD lpNumberOfBytesRead,
    LPOVERLAPPED lpOverlapped
);

BOOL WriteFile(
    HANDLE hFile,
    LPCVOID lpBuffer,
    DWORD nNumberOfBytesToWrite,
    LPDWORD lpNumberOfBytesWritten,
    LPOVERLAPPED lpOverlapped
);

BOOL CloseHandle(HANDLE hObject);

DWORD GetLastError(void);
BOOL DeleteFileA(const char *lpFileName);
BOOL MoveFileExA(const char *lpExistingFileName, const char *lpNewFileName, DWORD dwFlags);

#endif // TF_PSA_CRYPTO_COMPAT_WINDOWS_H
