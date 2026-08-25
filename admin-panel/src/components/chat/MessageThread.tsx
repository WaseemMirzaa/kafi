import { useEffect, useRef, useState } from 'react';
import { useLocale } from '../../context/LocaleContext';
import { getLocale } from '../../locales/t';

/** Normalized message shape the thread renders. Pages map their domain
 *  messages (chat messages, dispute messages) into this shape. */
export interface ThreadMessage {
  id: string;
  /** 'right' = the side we visually anchor right (e.g. nanny / admin). */
  align: 'left' | 'right';
  author?: string;
  content: string;
  timestamp: Date;
  /** System / trial-event messages render in a muted, centered style. */
  subtle?: boolean;
}

function timeLabel(d: Date): string {
  return d.toLocaleString(getLocale() === 'ar' ? 'ar-AE' : 'en-GB', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function Bubble({ m }: { m: ThreadMessage }) {
  if (m.subtle) {
    return (
      <div className="flex justify-center my-1">
        <div className="text-[8.5px] font-semibold text-[#8090B0] bg-[#F4F5FC] rounded-full px-2.5 py-1 max-w-[80%] text-center">
          {m.content}
          <span className="ml-1 text-[#A0ADC8]">· {timeLabel(m.timestamp)}</span>
        </div>
      </div>
    );
  }
  const right = m.align === 'right';
  return (
    <div className={`flex ${right ? 'justify-end' : 'justify-start'} my-1`}>
      <div className={`max-w-[78%] ${right ? 'items-end' : 'items-start'} flex flex-col`}>
        {m.author && (
          <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-0.5 px-1">
            {m.author}
          </div>
        )}
        <div
          className={`text-[10px] font-semibold leading-relaxed rounded-2xl px-3 py-1.5 ${
            right ? 'bg-purple text-white rounded-br-sm' : 'bg-[#F4F5FC] text-navy rounded-bl-sm'
          }`}
        >
          {m.content}
        </div>
        <div className="text-[7.5px] font-semibold text-[#A0ADC8] mt-0.5 px-1">{timeLabel(m.timestamp)}</div>
      </div>
    </div>
  );
}

export function MessageThread({
  messages,
  emptyText,
  onSend,
  sending,
  placeholder,
  fill = false,
}: {
  messages: ThreadMessage[];
  emptyText?: string;
  /** When provided, a composer is rendered and admin can post a reply. */
  onSend?: (text: string) => void | Promise<void>;
  sending?: boolean;
  placeholder?: string;
  /** Fill the parent's height (for modal/full-screen) instead of capping at 360px. */
  fill?: boolean;
}) {
  const { t } = useLocale();
  const [text, setText] = useState('');
  const listRef = useRef<HTMLDivElement>(null);

  // Keep the view anchored to the latest message (chat-style): jump to the
  // bottom whenever messages load or a new one arrives.
  useEffect(() => {
    const el = listRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [messages]);

  const submit = async () => {
    const t = text.trim();
    if (!t || !onSend) return;
    await onSend(t);
    setText('');
  };

  return (
    <div className={`flex flex-col ${fill ? 'h-full' : ''}`}>
      {/* Inner-scrollable message panel; the page itself never scrolls for chat. */}
      <div
        ref={listRef}
        className={`overflow-y-auto px-2 py-1.5 ${
          fill ? 'flex-1 min-h-0' : 'h-[340px] rounded-lg border border-[#EBEEF8] bg-[#FBFCFF]'
        }`}
      >
        {/* Bottom-anchor short threads so messages sit at the composer like a real chat. */}
        <div className={`min-h-full flex flex-col ${messages.length ? 'justify-end' : 'justify-center items-center'}`}>
          {messages.length === 0 ? (
            <div className="text-[10px] text-[#8090B0] px-2 py-4">{emptyText ?? t('chat.noMessagesYetShort')}</div>
          ) : (
            messages.map((m) => <Bubble key={m.id} m={m} />)
          )}
        </div>
      </div>
      {onSend && (
        <div className="flex items-end gap-1.5 mt-2 pt-2 border-t border-[#F4F5FC]">
          <textarea
            rows={2}
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) submit();
            }}
            placeholder={placeholder ?? t('chat.typeReplyPlaceholder')}
            className="flex-1 admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none resize-none"
          />
          <button
            type="button"
            className="qa-btn qa-p"
            onClick={submit}
            disabled={!text.trim() || sending}
          >
            {t('common.send')}
          </button>
        </div>
      )}
    </div>
  );
}
