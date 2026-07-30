import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import {
  DetailCard,
  Field,
  FieldGrid,
  PageContent,
  PageHeader,
  PageShell,
  QaLink,
  StatusBadge,
} from '../../components/ui/AdminUI';
import { Section } from '../../components/nanny/NannyProfileView';
import { MessageThread, ThreadMessage } from '../../components/chat/MessageThread';
import { TicketService, TicketRow, TicketMessageRow } from '../../services/firestore';

const categoryLabel: Record<TicketRow['category'], string> = {
  account: 'Account',
  payment: 'Payment',
  trial: 'Trial',
  hiring: 'Hiring',
  technical: 'Technical',
  other: 'Other',
};

const statusVariant: Record<TicketRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  closed: 'rejected',
};

const STATUSES: TicketRow['status'][] = ['open', 'investigating', 'resolved', 'closed'];

function toThreadMessages(msgs: TicketMessageRow[]): ThreadMessage[] {
  return msgs.map((m) => ({
    id: m.id,
    align: m.senderType === 'admin' ? 'right' : 'left',
    author: m.senderName ?? (m.senderType === 'admin' ? 'Support' : 'User'),
    content: m.content,
    timestamp: m.createdAt,
  }));
}

export default function SupportTicketDetail() {
  const { id } = useParams();
  const [ticket, setTicket] = useState<TicketRow | null>(null);
  const [messages, setMessages] = useState<TicketMessageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    setError(null);
    try {
      const [t, m] = await Promise.all([TicketService.get(id), TicketService.listMessages(id)]);
      setTicket(t);
      setMessages(m);
    } catch (e) {
      // A read failure previously fell through to the "Not found." branch,
      // misleading the admin; surface it as an error instead.
      setError((e as Error).message || 'Failed to load ticket');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  if (loading) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">Loading…</div>
        </PageContent>
      </PageShell>
    );
  }
  if (error && !ticket) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] font-bold text-rose-dark">{error}</div>
        </PageContent>
      </PageShell>
    );
  }
  if (!ticket) {
    return (
      <PageShell>
        <PageContent>
          <div className="text-[10px] text-[#8090B0]">Not found.</div>
        </PageContent>
      </PageShell>
    );
  }

  const send = async (text: string) => {
    setSending(true);
    setActionError(null);
    try {
      await TicketService.sendMessage(ticket.id, text);
      const [t, m] = await Promise.all([
        TicketService.get(ticket.id),
        TicketService.listMessages(ticket.id),
      ]);
      setTicket(t);
      setMessages(m);
    } catch (e) {
      // Keep the composer usable instead of leaving it spinning with the reply
      // silently lost.
      setActionError((e as Error).message || 'Failed to send reply — try again.');
    } finally {
      setSending(false);
    }
  };

  const setStatus = async (status: TicketRow['status']) => {
    setBusy(true);
    setActionError(null);
    try {
      await TicketService.updateStatus(ticket.id, status);
      await load();
    } catch (e) {
      setActionError((e as Error).message || 'Failed to update status — try again.');
    } finally {
      setBusy(false);
    }
  };

  const closed = ticket.status === 'resolved' || ticket.status === 'closed';

  return (
    <PageShell>
      <PageHeader
        title={ticket.subject || 'Support ticket'}
        subtitle={`Ticket #${ticket.id}`}
        actions={
          <QaLink to="/support" variant="n">
            ← All tickets
          </QaLink>
        }
      />
      <PageContent>
        <DetailCard>
          <div className="flex items-center gap-2">
            <div className="text-[12px] font-black text-navy">{categoryLabel[ticket.category]}</div>
            <StatusBadge variant={statusVariant[ticket.status]}>{ticket.status}</StatusBadge>
            <div className="flex-1 min-w-0 text-[8.5px] font-semibold text-[#8090B0] truncate">
              {ticket.openerName ?? ticket.openerId} ({ticket.openerType}) · {ticket.createdAt.toLocaleDateString()}
            </div>
          </div>
          <FieldGrid>
            <Field label="Opened by" value={`${ticket.openerName ?? ticket.openerId} (${ticket.openerType})`} />
            <Field label="Category" value={categoryLabel[ticket.category]} />
            <Field label="Related trial" value={ticket.relatedTrialId ?? '—'} />
            <Field label="Opened on" value={ticket.createdAt.toLocaleDateString()} />
          </FieldGrid>
        </DetailCard>

        {actionError && (
          <div className="text-[10px] font-bold text-rose-dark">{actionError}</div>
        )}

        <Section title="Conversation">
          <p className="text-[9px] font-semibold text-[#8090B0] mb-1">
            Conversation between support (you) and {ticket.openerName ?? 'the user'}.
          </p>
          <MessageThread
            messages={toThreadMessages(messages)}
            emptyText="No messages yet — send the first reply."
            onSend={closed ? undefined : send}
            sending={sending}
            placeholder="Reply to the user…"
          />
          {closed && (
            <div className="text-[9px] font-semibold text-[#8090B0] mt-2">
              This ticket is {ticket.status}. Re-open it below to continue.
            </div>
          )}
        </Section>

        <Section title="Status">
          <div className="flex flex-wrap gap-1.5 mt-2">
            {STATUSES.map((s) => (
              <button
                key={s}
                type="button"
                className={`qa-btn ${ticket.status === s ? 'qa-p' : 'qa-n'}`}
                disabled={busy}
                onClick={() => setStatus(s)}
              >
                {s}
              </button>
            ))}
          </div>
        </Section>
      </PageContent>
    </PageShell>
  );
}
