/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "command_result.h"

CommandResult::CommandResult(int exitCode, const QStringList &args,
                             const QString &stdout, const QString &stderr,
                             QObject *parent)
    : QObject(parent), m_exitCode(exitCode), m_args(args), m_stdout(stdout),
      m_stderr(stderr)
{
}

int CommandResult::exitCode() const
{
    return m_exitCode;
}

QStringList CommandResult::args() const
{
    return m_args;
}

QString CommandResult::stdout() const
{
    return m_stdout;
}

QString CommandResult::stderr() const
{
    return m_stderr;
}
