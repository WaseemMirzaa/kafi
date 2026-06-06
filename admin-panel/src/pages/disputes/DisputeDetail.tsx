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
import {
  DisputeService,
  DisputeRow,
  DisputeMessageRow,
} from '../../services/firestore';

const categoryLabel: Record<DisputeRow['category'], string> = {
  fraud: 'Fraud',
  abuse: 'Abuse',
  no_show: 'No show',
  payment: 'Payment',
  other: 'Other',
};

const statusVariant: Record<DisputeRow['status'], string> = {
  open: 'verify',
  investigating: 'new',
  resolved: 'verified',
  dismissed: 'rejected',
};

function toThreadMessages(msgs: DisputeMessageRow[]): ThreadMessage[] {
  return msgs.map((m) => ({
    id: m.id,
    align: m.senderType === 'admin' ? 'right' : 'left',
    author: m.senderName ?? (m.senderType === 'admin' ? 'Support' : 'User'),
    content: m.content,
    timestamp: m.createdAt,
  }));
}

export default function DisputeDetail() {
  const { id } = useParams();
  const [dispute, setDispute] = useState<DisputeRow | null>(null);
  const [messages, setMessages] = useState<DisputeMessageRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [resolution, setResolution] = useState('');
  const [decision, setDecision] = useState<'resolved' | 'dismissed'>('resolved');
  const [busy, setBusy] = useState(false);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    const [d, m] = await Promise.all([DisputeService.get(id), DisputeService.listMessages(id)]);
    setDispute(d);
    setMessages(m);
    setLoading(false);
  };

  useEffect(() => {
    load();
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
  if (!dispute) {
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
    await DisputeService.sendMessage(dispute.id, text);
    const [d, m] = await Promise.all([DisputeService.get(dispute.id), DisputeService.listMessages(dispute.id)]);
    setDispute(d);
    setMessages(m);
    setSending(false);
  };

  const resolve = async () => {
    if (!resolution.trim()) return;
    setBusy(true);
    await DisputeService.resolve(dispute.id, resolution.trim(), decision);
    setResolution('');
    setBusy(false);
    load();
  };

  const closed = dispute.status === 'resolved' || dispute.status === 'dismissed';

  return (
    <PageShell>
      <PageHeader
        title={`${categoryLabel[dispute.category]} dispute`}
        subtitle={`Dispute #${dispute.id}`}
        actions={
          <QaLink to="/disputes" variant="n">
            ← All disputes
          </QaLink>
        }
      />
      <PageContent>
        <DetailCard>
          <div className="flex items-center justify-between gap-2">
            <div className="text-[12px] font-black text-navy">{categoryLabel[dispute.category]}</div>
            <StatusBadge variant={statusVariant[dispute.status]}>{dispute.status}</StatusBadge>
          </div>
          <FieldGrid>
            <Field
              label="Reporter"
              value={`${dispute.reporterName ?? dispute.reporterId}${dispute.reporterType ? ` (${dispute.reporterType})` : ''}`}
            />
            <Field label="Reported user" value={dispute.reportedName ?? dispute.reportedUserId} />
            <Field label="Category" value={categoryLabel[dispute.category]} />
            <Field label="Related trial" value={dispute.relatedTrialId ?? '—'} />
            <Field label="Filed on" value={dispute.createdAt.toLocaleDateString()} />
          </FieldGrid>
          <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mt-3">Description</div>
          <p className="text-[10.5px] font-semibold text-navy/80 leading-relaxed mt-0.5">{dispute.description}</p>
          {dispute.resolution && (
            <div className="mt-3 rounded-lg bg-green-pale px-3 py-2">
              <div className="text-[8px] font-bold text-green-dark uppercase tracking-wide">Resolution</div>
              <p className="text-[10px] font-semibold text-navy/80 mt-0.5">{dispute.resolution}</p>
            </div>
          )}
        </DetailCard>

        <Section title="Support chat">
          <p className="text-[9px] font-semibold text-[#8090B0] mb-1">
            Conversation between support (you) and {dispute.reporterName ?? 'the reporting user'}.
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
              This dispute is {dispute.status}. Re-open is not available from the admin panel.
            </div>
          )}
        </Section>

        {!closed && (
          <Section title="Resolve dispute">
            <div className="flex gap-1.5 mt-2 mb-2">
              <button
                type="button"
                className={`qa-btn ${decision === 'resolved' ? 'qa-g' : 'qa-n'}`}
                onClick={() => setDecision('resolved')}
              >
                Resolved
              </button>
              <button
                type="button"
                className={`qa-btn ${decision === 'dismissed' ? 'qa-r' : 'qa-n'}`}
                onClick={() => setDecision('dismissed')}
              >
                Dismissed
              </button>
            </div>
            <textarea
              rows={3}
              value={resolution}
              onChange={(e) => setResolution(e.target.value)}
              placeholder="Resolution notes (visible to both parties)"
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none resize-none"
            />
            <div className="flex justify-end mt-2">
              <button type="button" className="qa-btn qa-r" onClick={resolve} disabled={!resolution.trim() || busy}>
                Submit resolution
              </button>
            </div>
          </Section>
        )}
      </PageContent>
    </PageShell>
  );
}
