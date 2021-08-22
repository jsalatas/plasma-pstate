/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef COMMAND_RESULT_H
#define COMMAND_RESULT_H

#include <QtCore/QObject>


class CommandResult : public QObject {
    Q_OBJECT
    Q_PROPERTY(int exitCode READ exitCode)
    Q_PROPERTY(QStringList args READ args)
    Q_PROPERTY(QString stdout READ stdout)
    Q_PROPERTY(QString stderr READ stderr)

private:
    int m_exitCode;
    QStringList m_args;
    QString m_stdout;
    QString m_stderr;

public:
    CommandResult(int exitCode, const QStringList &args,
                  const QString &stdout, const QString &stderr,
                  QObject *parent = 0);

    int exitCode() const;
    QStringList args() const;
    QString stdout() const;
    QString stderr() const;

};

#endif
