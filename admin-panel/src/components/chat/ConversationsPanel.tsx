import { useEffect, useState } from 'react';
import { ChatService, ChatThreadRow, ChatMessageRow } from '../../services/firestore';
import { Avatar, StatusBadge } from '../ui/AdminUI';
import { gradientFor, initials } from '../../utils/avatar';
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

/** Read-only conversations viewer: a list of threads; tapping one opens that
 *  conversation in its own popup with the messages scrollable inside. Used on
 *  both nanny and family detail pages so admins can audit all messages. */
export function ConversationsPanel({
  threads,
  counterpart,
}: {
  threads: ChatThreadRow[];
  /** Which name to show as the conversation label ('family' | 'nanny'). */
  counterpart: 'family' | 'nanny';
}) {
  const [open, setOpen] = useState<ChatThreadRow | null>(null);
  const [messages, setMessages] = useState<ChatMessageRow[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!open) return;
    setLoading(true);
    setMessages([]);
    ChatService.listMessages(open.id)
      .then(setMessages)
      .finally(() => setLoading(false));
  }, [open]);

  if (threads.length === 0) {
    return <div className="text-[10px] text-[#8090B0] mt-2">No conversations yet.</div>;
  }

  const nameOf = (t: ChatThreadRow) => (counterpart === 'family' ? t.familyName : t.nannyName) ?? 'Conversation';
  const keyOf = (t: ChatThreadRow) => (counterpart === 'family' ? t.familyId : t.nannyId);

  return (
    <>
      <div className="flex flex-col gap-1 mt-2">
        {threads.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => setOpen(t)}
            className="flex items-center gap-2.5 text-left rounded-lg border border-[#EBEEF8] px-2.5 py-2 hover:bg-[#F8F9FD] transition-colors"
          >
            <Avatar letter={initials(nameOf(t))} gradient={gradientFor(keyOf(t))} />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <div className="text-[10px] font-extrabold text-navy truncate">{nameOf(t)}</div>
                {t.trialStatus && (
                  <StatusBadge variant={t.trialStatus === 'active' ? 'verified' : 'pending'}>{t.trialStatus}</StatusBadge>
                )}
              </div>
              <div className="text-[8.5px] font-semibold text-[#8090B0] truncate mt-0.5">{t.lastMessage ?? '—'}</div>
            </div>
            <span className="text-[8px] font-semibold text-[#A0ADC8] flex-shrink-0">
              {t.lastMessageAt.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })}
            </span>
            <span className="text-[9px] font-bold text-purple font-fredoka flex-shrink-0">Open →</span>
          </button>
        ))}
      </div>

      {open && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center px-4 py-6">
          <div className="admin-card w-full max-w-lg max-h-[85vh] flex flex-col overflow-hidden">
            {/* Header */}
            <div className="flex items-center gap-2.5 px-4 py-3 border-b border-[#EBEEF8] flex-shrink-0">
              <Avatar letter={initials(nameOf(open))} gradient={gradientFor(keyOf(open))} />
              <div className="flex-1 min-w-0">
                <div className="text-[12px] font-black text-navy truncate">{nameOf(open)}</div>
                <div className="text-[8.5px] font-semibold text-[#8090B0] truncate">
                  {open.familyName} ↔ {open.nannyName}
                </div>
              </div>
              {open.trialStatus && (
                <StatusBadge variant={open.trialStatus === 'active' ? 'verified' : 'pending'}>
                  Trial {open.trialStatus}
                </StatusBadge>
              )}
              <button
                type="button"
                className="text-[16px] font-bold text-[#8090B0] hover:text-navy px-1"
                onClick={() => setOpen(null)}
                aria-label="Close"
              >
                ×
              </button>
            </div>

            {/* Scrollable messages — fills the modal body */}
            <div className="flex-1 min-h-0 flex flex-col px-3 py-2 bg-[#FBFCFF]">
              {loading ? (
                <div className="text-[10px] text-[#8090B0] px-2 py-4">Loading messages…</div>
              ) : (
                <MessageThread messages={toThreadMessages(messages, open)} fill />
              )}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
