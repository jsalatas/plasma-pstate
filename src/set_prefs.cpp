/*
    SPDX-FileCopyrightText: 2021 Vincent Grabner <frankenfruity@protonmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#include "set_prefs.h"
#include "pstate.h"
#include "command_result.h"


#define SET_PREFS_SCRIPT "/usr/share/plasma/plasmoids/" \
                         "gr.ictpro.jsalatas.plasma.pstate/contents/code/" \
                         "set_prefs.sh"

SetPrefs::SetPrefs(QObject *parent) :
    QObject(parent), m_codec(QTextCodec::codecForName("UTF-8"))
{
    connect(&m_proc, SIGNAL(readyRead()), this, SLOT(read()));
    connect(&m_proc, SIGNAL(started()), this, SLOT(started()));
    connect(&m_proc, SIGNAL(finished(int)), this, SLOT(finished()));

    m_proc.start("sudo", {"-n" SET_PREFS_SCRIPT, "-daemon"});
    m_proc.waitForStarted();
}

SetPrefs::~SetPrefs()
{
    m_proc.write("-exit\n");
    m_proc.waitForFinished(1000);
    m_proc.terminate();

    disconnect(&m_proc, SIGNAL(readyRead()), this, SLOT(read()));
    disconnect(&m_proc, SIGNAL(started()), this, SLOT(started()));
    disconnect(&m_proc, SIGNAL(finished(int)), this, SLOT(finished()));
}

void SetPrefs::read()
{
    while (m_proc.canReadLine()) {
        QByteArray line = m_proc.readLine();
        QByteArray stderr_buf = m_proc.readAllStandardError();

        if (m_args.size() == 0) {
            fprintf(stderr, "Read a line while having an empty command queue."
                            "Expected at least one command in the queue");
            continue;
        }

        QStringList& args = m_args.front();
        QString stdout = m_codec->toUnicode(line).trimmed();
        QString stderr = m_codec->toUnicode(stderr_buf).trimmed();
        int exitCode = stderr.size() == 0 ? 0 : 1;

        // qDebug() << "args:" << args;
        // qDebug() << "stdout:" << stdout;
        // qDebug() << "stderr:" << stdout;

        CommandResult data(exitCode, args, stdout, stderr);
        emit commandFinished(&data);

        m_args.pop_front();
    }
}

void SetPrefs::started()
{
    emit procStarted();
}

void SetPrefs::finished()
{
    emit procFinished();
}

void SetPrefs::runCommand(QStringList args)
{
    m_args.push_back(args);
    QString str = args.join(" ").append('\n');
    m_proc.write(str.toUtf8());
}

#include "set_prefs.moc"
