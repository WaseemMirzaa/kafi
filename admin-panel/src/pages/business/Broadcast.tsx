import { useEffect, useState } from 'react';
import {
  DetailCard,
  PageContent,
  PageHeader,
  PageShell,
  Row,
  TableCard,
} from '../../components/ui/AdminUI';
import { BroadcastService } from '../../services/firestore';

type Audience = 'all' | 'nannies' | 'families' | 'subscribers';

const audienceLabel: Record<Audience, string> = {
  all: 'All users',
  nannies: 'Nannies only',
  families: 'Families only',
  subscribers: 'Subscribers only',
};

export default function Broadcast() {
  const [audience, setAudience] = useState<Audience>('all');
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const [ok, setOk] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [recent, setRecent] = useState<{ id: string; audience: string; title: string; message: string; createdAt: Date }[]>([]);

  const load = async () => {
    try {
      setRecent(await BroadcastService.listRecent());
    } catch (e) {
      setError((e as Error).message || 'Failed to load history');
    }
  };
  useEffect(() => {
    load();
  }, []);

  const send = async () => {
    if (!title.trim() || !message.trim()) return;
    setBusy(true);
    setOk(null);
    setError(null);
    try {
      const id = await BroadcastService.send(audience, title.trim(), message.trim());
      setOk(`Queued #${id}`);
      setTitle('');
      setMessage('');
      await load();
    } catch (e) {
      setError((e as Error).message || 'Failed to send broadcast');
    } finally {
      setBusy(false);
    }
  };

  return (
    <PageShell>
      <PageHeader title="Broadcast" subtitle="Send push notifications to users" />
      <PageContent>
        <DetailCard>
          <div className="mb-4">
            <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">Target audience</div>
            <div className="flex gap-1.5 flex-wrap">
              {(['all', 'nannies', 'families', 'subscribers'] as Audience[]).map((t) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => setAudience(t)}
                  className={`qa-btn ${audience === t ? 'qa-r' : 'qa-n'}`}
                >
                  {audienceLabel[t]}
                </button>
              ))}
            </div>
          </div>
          <div className="mb-3">
            <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">Title</div>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Notification title (shown in push)"
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
            />
          </div>
          <div className="mb-4">
            <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">Message</div>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={4}
              placeholder="Enter your broadcast message..."
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30 resize-none"
            />
          </div>
          <div className="flex items-center gap-2">
            <button type="button" className="qa-btn qa-r" disabled={!title.trim() || !message.trim() || busy} onClick={send}>
              {busy ? 'Sending…' : 'Send broadcast'}
            </button>
            {ok && <span className="text-[10px] font-bold text-[#2A8A50]">{ok}</span>}
            {error && <span className="text-[10px] font-bold text-rose-dark">{error}</span>}
          </div>
        </DetailCard>

        <div className="mt-3">
          <TableCard title="Recent broadcasts">
            {recent.length === 0 && (
              <div className="px-3 py-4 text-[10px] text-[#8090B0]">No broadcasts yet.</div>
            )}
            {recent.map((b) => (
              <Row key={b.id}>
                <div className="flex-1 min-w-0">
                  <div className="text-[10.5px] font-extrabold text-navy">{b.title}</div>
                  <div className="text-[8.5px] font-semibold text-[#8090B0]">
                    {b.audience} · {b.createdAt.toLocaleString()} · {b.message.substring(0, 60)}
                  </div>
                </div>
              </Row>
            ))}
          </TableCard>
        </div>
      </PageContent>
    </PageShell>
  );
}
