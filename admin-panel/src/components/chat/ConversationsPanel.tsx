import { useEffect, useState } from 'react';
import { ChatService, ChatThreadRow, ChatMessageRow } from '../../services/firestore';
import { StatusBadge } from '../ui/AdminUI';
import { MessageThread, ThreadMessage } from './MessageThread';

const typeNote: Record<string, string> = {
  trialOffer: 'sent a trial offer',
  trialAccepted: 'accepted the trial offer',
  trialDeclined: 'declined the trial offer',
  trialCountered: 'sent a counter-offer',
  system: '',
};

function toThreadMessages(msgs: ChatMessageRow[], thread: ChatThreadRow): ThreadMessage[] {
  return msgs.map((m) => {
    const isNanny = m.senderType === 'nanny';
    const author = isNanny ? thread.nannyName ?? 'Nanny' : thread.familyName ?? 'Family';
    const note = m.type && m.type !== 'text' && m.type !== 'image' ? typeNote[m.type] : undefined;
    if (m.type === 'system') {
      return { id: m.id, align: 'left', content: m.content, timestamp: m.createdAt, subtle: true };
    }
    return {
      id: m.id,
      align: isNanny ? 'right' : 'left',
      author: note ? `${author} · ${note}` : author,
      content: m.content,
      timestamp: m.createdAt,
      subtle: !!note,
    };
  });
}

/** Read-only conversations viewer: a list of threads on the left, the selected
 *  thread's messages on the right. Used on both nanny and family detail pages so
 *  admins can audit all messages between a nanny and a family. */
export function ConversationsPanel({
  threads,
  counterpart,
}: {
  threads: ChatThreadRow[];
  /** Which name to show as the conversation label ('family' | 'nanny'). */
  counterpart: 'family' | 'nanny';
}) {
  const [selected, setSelected] = useState<ChatThreadRow | null>(threads[0] ?? null);
  const [messages, setMessages] = useState<ChatMessageRow[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!threads.length) return;
    if (!selected) setSelected(threads[0]);
  }, [threads, selected]);

  useEffect(() => {
    if (!selected) return;
    setLoading(true);
    ChatService.listMessages(selected.id)
      .then(setMessages)
      .finally(() => setLoading(false));
  }, [selected]);

  if (threads.length === 0) {
    return <div className="text-[10px] text-[#8090B0] mt-2">No conversations yet.</div>;
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-[200px_1fr] gap-3 mt-2">
      <div className="flex flex-col gap-1">
        {threads.map((t) => {
          const name = counterpart === 'family' ? t.familyName : t.nannyName;
          const active = selected?.id === t.id;
          return (
            <button
              key={t.id}
              type="button"
              onClick={() => setSelected(t)}
              className={`text-left rounded-lg border px-2.5 py-2 transition-colors ${
                active ? 'border-purple bg-purple-light' : 'border-[#EBEEF8] hover:bg-[#F8F9FD]'
              }`}
            >
              <div className="flex items-center justify-between gap-1">
                <div className="text-[10px] font-extrabold text-navy truncate">{name ?? 'Conversation'}</div>
                {t.trialStatus && (
                  <StatusBadge variant={t.trialStatus === 'active' ? 'verified' : 'pending'}>
                    {t.trialStatus}
                  </StatusBadge>
                )}
              </div>
              <div className="text-[8.5px] font-semibold text-[#8090B0] truncate mt-0.5">
                {t.lastMessage ?? '—'}
              </div>
            </button>
          );
        })}
      </div>
      <div className="rounded-lg border border-[#EBEEF8] p-2">
        {loading ? (
          <div className="text-[10px] text-[#8090B0] px-2 py-4">Loading messages…</div>
        ) : (
          selected && <MessageThread messages={toThreadMessages(messages, selected)} />
        )}
      </div>
    </div>
  );
}
