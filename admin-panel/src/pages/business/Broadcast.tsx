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
import { useLocale } from '../../context/LocaleContext';
import { TranslationKey } from '../../locales/t';

type Audience = 'all' | 'nannies' | 'families' | 'subscribers';

const audienceLabelKeys: Record<Audience, TranslationKey> = {
  all: 'broadcast.audience.all',
  nannies: 'broadcast.audience.nannies',
  families: 'broadcast.audience.families',
  subscribers: 'broadcast.audience.subscribers',
};

export default function Broadcast() {
  const { t } = useLocale();
  const [audience, setAudience] = useState<Audience>('all');
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);
  const [ok, setOk] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [confirming, setConfirming] = useState(false);
  const [recent, setRecent] = useState<{ id: string; audience: string; title: string; message: string; createdAt: Date }[]>([]);

  const load = async () => {
    try {
      setRecent(await BroadcastService.listRecent());
    } catch (e) {
      setError((e as Error).message || t('broadcast.failedToLoadHistory'));
    }
  };
  useEffect(() => {
    load();
  }, []);

  const send = async () => {
    if (!title.trim() || !message.trim()) return;
    setConfirming(false);
    setBusy(true);
    setOk(null);
    setError(null);
    try {
      const id = await BroadcastService.send(audience, title.trim(), message.trim());
      setOk(t('broadcast.queued', { id }));
      setTitle('');
      setMessage('');
      await load();
    } catch (e) {
      setError((e as Error).message || t('broadcast.failedToSend'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <PageShell>
      <PageHeader title={t('broadcast.title')} subtitle={t('broadcast.subtitle')} />
      <PageContent>
        <DetailCard>
          <div className="mb-4">
            <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">{t('broadcast.targetAudience')}</div>
            <div className="flex gap-1.5 flex-wrap">
              {(['all', 'nannies', 'families', 'subscribers'] as Audience[]).map((a) => (
                <button
                  key={a}
                  type="button"
                  onClick={() => setAudience(a)}
                  className={`qa-btn ${audience === a ? 'qa-r' : 'qa-n'}`}
                >
                  {t(audienceLabelKeys[a])}
                </button>
              ))}
            </div>
          </div>
          <div className="mb-3">
            <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">{t('broadcast.notifTitle')}</div>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={t('broadcast.notifTitlePlaceholder')}
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30"
            />
          </div>
          <div className="mb-4">
            <div className="text-[8px] font-bold text-[#8090B0] uppercase tracking-wide mb-2">{t('broadcast.message')}</div>
            <textarea
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              rows={4}
              placeholder={t('broadcast.messagePlaceholder')}
              className="w-full admin-card text-[10px] font-semibold text-navy px-3 py-2 border-[#EBEEF8] focus:outline-none focus:ring-1 focus:ring-rose-dark/30 resize-none"
            />
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              className="qa-btn qa-r"
              disabled={!title.trim() || !message.trim() || busy}
              onClick={() => setConfirming(true)}
            >
              {busy ? t('broadcast.sending') : t('broadcast.sendBroadcast')}
            </button>
            {ok && <span className="text-[10px] font-bold text-[#2A8A50]">{ok}</span>}
            {error && <span className="text-[10px] font-bold text-rose-dark">{error}</span>}
          </div>
        </DetailCard>

        <div className="mt-3">
          <TableCard title={t('broadcast.recentBroadcasts')}>
            {recent.length === 0 && (
              <div className="px-3 py-4 text-[10px] text-[#8090B0]">{t('broadcast.noneYet')}</div>
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

      {confirming && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
          onClick={() => setConfirming(false)}
        >
          <div className="admin-card w-full max-w-sm p-4" onClick={(e) => e.stopPropagation()}>
            <div className="text-[12px] font-extrabold text-navy mb-1.5">{t('broadcast.confirmTitle')}</div>
            <div className="text-[10px] font-semibold text-[#8090B0] leading-relaxed mb-3">
              {t('broadcast.confirmDesc', { title: title.trim(), audience: t(audienceLabelKeys[audience]) })}
            </div>
            <div className="flex items-center justify-end gap-2">
              <button type="button" className="qa-btn qa-n" onClick={() => setConfirming(false)}>
                {t('common.cancel')}
              </button>
              <button type="button" className="qa-btn qa-r" disabled={busy} onClick={send}>
                {busy ? t('broadcast.sending') : t('broadcast.sendNow')}
              </button>
            </div>
          </div>
        </div>
      )}
    </PageShell>
  );
}
