#ifndef TF_PSA_CRYPTO_COMPAT_UNISTD_H
#define TF_PSA_CRYPTO_COMPAT_UNISTD_H

// POSIX unistd.h 最基本定义

// 文件操作常量
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

// 用于读取/写入函数的 ssize_t 类型
typedef long ssize_t;

// 进程 ID 类型和函数
typedef int pid_t;
pid_t getpid(void);

#endif // TF_PSA_CRYPTO_COMPAT_UNISTD_H
